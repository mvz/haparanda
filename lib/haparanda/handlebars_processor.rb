# frozen_string_literal: true

require "sexp_processor"

module Haparanda
  class HandlebarsProcessor < SexpProcessor # rubocop:disable Metrics/ClassLength
    class SafeString < String
      def to_s
        self
      end
    end

    module ValueDigger
      private

      def dig_value(value, keys)
        keys.each do |key|
          next if %i[. this].include? key

          value = case value
                  when Hash
                    value[key]
                  when nil
                    nil
                  else
                    value.send key
                  end
        end

        value
      end
    end

    class Input
      include ValueDigger

      def initialize(value)
        @stack = [value]
      end

      def dig(*keys)
        index = -1
        while keys.first == :".."
          keys.shift
          index -= 1
        end

        value = @stack[index]
        dig_value(value, keys)
      end

      def with_new_context(value, &block)
        # TODO: This prevents a SystemStackError. Make this unnecessary, for
        # example by moving the stacking behavior out of the Input class.
        if self == value
          block.call
        else
          @stack.push value
          result = block.call
          @stack.pop
          result
        end
      end

      def to_s
        @stack.last.to_s
      end

      def this
        self
      end

      def respond_to_missing?(_method_name, *_args)
        true
      end

      def method_missing(method_name, *_args)
        dig(method_name)
      end
    end

    class Data
      def initialize(data = {})
        @data = data
      end

      def data(*keys)
        @data.dig(*keys)
      end

      def set_data(key, value)
        @data[key] = value
      end

      def with_new_data(&block)
        data = @data.clone
        result = block.call
        @data = data
        result
      end

      def respond_to_missing?(method_name)
        @data.key? method_name
      end

      def method_missing(method_name, *_args)
        @data[method_name] if @data.key? method_name
      end
    end

    class NoData
      def set_data(key, value); end

      def with_new_data(&block)
        block.call
      end
    end

    class Options
      def initialize(fn:, inverse:, hash:, data:, block_params:)
        @fn = fn
        @inverse = inverse
        @hash = hash
        @data = data
        @block_params = block_params
      end

      attr_reader :hash, :data, :block_params

      def fn(arg = nil, options = {})
        @fn&.call(arg, options)
      end

      def inverse(arg = nil)
        @inverse&.call(arg)
      end
    end

    class HelperContext
      def initialize(input)
        @input = input
      end

      def this
        @input
      end
    end

    class BlockParameterList
      include ValueDigger

      def initialize
        @values = {}
      end

      def with_new_values(&block)
        values = @values.clone
        result = block.call
        @values = values
        result
      end

      def key?(key)
        @values.key? key
      end

      def set_value(key, value)
        @values[key] = value
      end

      def value(key, *rest)
        dig_value(@values.fetch(key), rest)
      end
    end

    def initialize(input, custom_helpers = nil, data: {})
      super()

      self.require_empty = false

      @input = Input.new(input)
      @data = data ? Data.new(data) : NoData.new
      @helper_context = HelperContext.new(@input)
      @block_parameter_list = BlockParameterList.new

      custom_helpers ||= {}
      @helpers = {
        if: method(:handle_if),
        unless: method(:handle_unless),
        with: method(:handle_with),
        each: method(:handle_each)
      }.merge(custom_helpers)
    end

    def apply(expr)
      result = process(expr)
      result[1]
    end

    def process_root(expr)
      _, statements = expr
      process(statements)
    end

    def process_mustache(expr)
      _, path, params, hash, escaped, _strip = expr
      params = process(params)[1]
      hash = process(hash)[1] if hash
      data, elements = path_segments process(path)
      value = lookup_path(data, elements)
      value = execute_in_context(value, params, hash: hash) if value.respond_to? :call
      value = value.to_s
      value = escape(value) if escaped
      s(:result, value)
    end

    def process_block(expr)
      _, name, params, hash, program, inverse_chain, = expr
      hash = process(hash)[1] if hash
      else_program = inverse_chain.sexp_body[1] if inverse_chain
      arguments = process(params)[1]

      path = process(name)
      data, elements = path_segments(path)
      value = lookup_path(data, elements)

      evaluate_program_with_value(value, arguments, program, else_program, hash)
    end

    def process_statements(expr)
      results = expr.sexp_body.map { process(_1)[1] }
      s(:result, results.join)
    end

    def process_program(expr)
      _, _params, statements, = expr
      statements = process(statements)[1] if statements
      s(:result, statements.to_s)
    end

    def process_comment(expr)
      _, _comment, = expr
      s(:result, "")
    end

    def process_path(expr)
      _, data, *segments = expr
      segments = segments.each_slice(2).map { |elem, _sep| elem[1].to_sym }
      s(:segments, data, segments)
    end

    def process_exprs(expr)
      _, *paths = expr
      values = paths.map { evaluate_expr(_1) }
      s(:values, values)
    end

    def process_hash(expr)
      _, *entries = expr
      hash = entries.to_h do |_, key, value|
        value = evaluate_expr(value)
        [key.to_sym, value]
      end
      s(:hash, hash)
    end

    private

    def evaluate_program_with_value(value, arguments, program, else_program, hash)
      block_params = extract_block_param_names(program)
      fn = make_contextual_lambda(program, block_params)
      inverse = make_contextual_lambda(else_program)

      if value.respond_to? :call
        value = execute_in_context(value, arguments, fn: fn, inverse: inverse, hash: hash,
                                                     block_params: block_params&.count)
        return s(:result, value.to_s)
      end

      case value
      when Array
        return s(:result, inverse.call(@input)) if value.empty?

        parts = value.each_with_index.map do |elem, index|
          @data.set_data(:index, index)
          fn.call(elem)
        end
        s(:result, parts.join)
      else
        result = value ? fn.call(value) : inverse.call(@input)
        s(:result, result)
      end
    end

    def extract_block_param_names(program)
      return [] unless program&.sexp_type == :program

      if (params_definition = program[1])
        params_definition.sexp_body.map { _1[1].to_sym }
      else
        []
      end
    end

    def make_contextual_lambda(program, block_param_names = [])
      if program
        if block_param_names.any?
          lambda { |item, options = {}|
            with_new_input_context(item) do
              with_block_params(block_param_names, options[:block_params]) do
                apply(program)
              end
            end
          }
        else
          lambda { |item, _options = {}|
            with_new_input_context(item) { apply(program) }
          }
        end
      else
        ->(_item) { "" }
      end
    end

    def with_new_input_context(item, &)
      @input.with_new_context(item, &)
    end

    def with_block_params(block_param_names, block_param_values, &block)
      @block_parameter_list.with_new_values do
        if block_param_values
          block_param_names.zip(block_param_values) do |name, value|
            @block_parameter_list.set_value(name, value)
          end
        end
        block.call
      end
    end

    def evaluate_expr(expr)
      path = process(expr)
      case path.sexp_type
      when :segments
        data, elements = path.sexp_body
        value = lookup_path(data, elements)
        value = execute_in_context(value) if value.respond_to? :call
        value
      when :undefined, :null
        nil
      else
        path[1]
      end
    end

    def path_segments(path)
      case path.sexp_type
      when :segments
        data, elements = path.sexp_body
      when :undefined, :null
        elements = [path.sexp_type]
      else
        elements = [path[1]]
      end
      return data, elements
    end

    def lookup_path(data, elements)
      if data
        @data.data(*elements)
      elsif @block_parameter_list.key?(elements.first)
        @block_parameter_list.value(*elements)
      elsif elements.one? && @helpers.key?(elements.first)
        @helpers[elements.first]
      else
        @input.dig(*elements)
      end
    end

    def execute_in_context(callable, params = [],
                           fn: nil, inverse: nil, block_params: 0, hash: nil)
      arity = callable.arity
      num_params = params.count
      raise NotImplementedError if arity < 0

      params = params.take(arity) if num_params > arity

      options = Options.new(fn: fn, inverse: inverse,
                            block_params: block_params, hash: hash,
                            data: @data)
      params.push options if arity > num_params
      params.unshift @helper_context.this if arity > num_params + 1
      result = @helper_context.instance_exec(*params, &callable)
      result = fn.call(result) if fn && arity <= num_params
      result
    end

    def handle_if(context, value, options)
      if value
        options.fn(context)
      else
        options.inverse(context)
      end
    end

    def handle_unless(context, value, options)
      options.fn(context) unless value
    end

    def handle_with(_context, value, options)
      if value
        options.fn(value, block_params: [value])
      else
        options.inverse(value)
      end
    end

    def handle_each(_context, value, options)
      return unless value

      value = value.values if value.is_a? Hash
      last = value.length - 1
      @data.with_new_data do
        value.each_with_index.map do |item, index|
          @data.set_data(:index, index)
          @data.set_data(:first, index == 0)
          @data.set_data(:last, index == last)
          options.fn(item, block_params: [item, index])
        end.join
      end
    end

    ESCAPE = {
      "&" => "&amp;",
      "<" => "&lt;",
      ">" => "&gt;",
      '"' => "&quot;",
      "'" => "&#x27;",
      "`" => "&#x60;",
      "=" => "&#x3D;"
    }.freeze
    private_constant :ESCAPE

    def escape(str)
      return str if str.is_a? SafeString

      str.gsub(/[&<>"'`=]/) do |chr|
        ESCAPE[chr]
      end
    end
  end
end
