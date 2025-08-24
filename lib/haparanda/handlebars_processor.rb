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

      def respond_to_missing?(method_name, *_args)
        value = @stack.last
        case value
        when Hash
          value.key? method_name
        when nil
          false
        else
          value.respond_to? method_name
        end
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
      def initialize(fn:, inverse:, hash:, data:, block_params:, name: nil)
        @fn = fn
        @inverse = inverse
        @name = name
        @hash = hash
        @data = data
        @block_params = block_params
      end

      attr_reader :name, :hash, :data, :block_params

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

    module Utils
      module_function

      def escape(str)
        return str if str.is_a? SafeString

        str.gsub(/[&<>"'`=]/) do |chr|
          ESCAPE[chr]
        end
      end
    end

    def initialize(input, helpers: {}, partials: {}, data: {}, log: nil)
      super()

      self.require_empty = false

      @input = Input.new(input)
      @data = data ? Data.new(data) : NoData.new
      @helper_context = HelperContext.new(@input)
      @block_parameter_list = BlockParameterList.new

      @helpers = {
        if: method(:handle_if),
        unless: method(:handle_unless),
        with: method(:handle_with),
        each: method(:handle_each),
        log: method(:handle_log)
      }.merge(helpers)
      @partials = partials
      @log = log
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
      value, name = lookup_value(path)

      if value.nil?
        value = @helpers[:helperMissing]
        raise "Missing helper: \"#{name}\"" if value.nil? && !params.empty?
      end

      if value.respond_to? :call
        value = execute_in_context(value, params, name: name, hash: hash)
      end

      value = value.to_s
      value = Utils.escape(value) if escaped
      s(:result, value)
    end

    def process_block(expr)
      _, path, params, hash, program, inverse_chain, = expr
      hash = process(hash)[1] if hash
      else_program = inverse_chain.sexp_body[1] if inverse_chain
      arguments = process(params)[1]

      value, name = lookup_value(path)

      evaluate_program_with_value(value, arguments, program, else_program, hash, name: name)
    end

    def process_partial(expr)
      _, name, context, = expr

      path = process(name)
      _data, _name, elements = path_segments(path)

      partial = @partials.fetch elements.first.to_s

      values = process(context)
      value = values[1].first

      if value
        program = make_contextual_lambda partial

        result = case value
                 when Array
                   value.map { |item| program.call item }.join
                 else
                   program.call value
                 end
        s(:result, result)
      else
        process(partial)
      end
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
      name_parts = segments.map { |seg| seg[1] }
      segments = name_parts.each_slice(2).map { |elem, _sep| elem.to_sym }
      name = name_parts.join
      s(:segments, data, name, segments)
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

    def process_sub_expression(expr)
      _, path, params, hash = expr
      value, name = lookup_value(path)

      arguments = process(params)[1]
      hash = process(hash)[1] if hash

      result = execute_in_context(value, arguments, hash: hash, name: name)
      s(:result, result)
    end

    private

    # rubocop:todo Metrics/PerceivedComplexity
    # rubocop:todo Metrics/MethodLength
    # rubocop:todo Metrics/AbcSize
    # rubocop:todo Metrics/CyclomaticComplexity
    def evaluate_program_with_value(value, arguments, program, else_program, hash,
                                    name: nil)
      block_params = extract_block_param_names(program)
      fn = make_contextual_lambda(program, block_params)
      inverse = make_contextual_lambda(else_program)

      if value.nil? && (hash || arguments.any?)
        value = @helpers[:helperMissing] or raise "Missing helper: \"#{name}\""
      end

      while value.respond_to?(:call)
        value = execute_in_context(value, arguments, name: name,
                                                     fn: fn, inverse: inverse, hash: hash,
                                                     block_params: block_params&.count)
      end
      return s(:result, value.to_s) if arguments.any?

      if (helper = @helpers[:blockHelperMissing])
        value = execute_in_context(helper, [value], name: name,
                                                    fn: fn, inverse: inverse, hash: hash,
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
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

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
      case expr.sexp_type
      when :path
        value, name = lookup_value(expr)
        value = execute_in_context(value, name: name) if value.respond_to? :call
        value
      when :undefined, :null
        nil
      else
        process(expr)[1]
      end
    end

    def lookup_value(expr)
      path = process(expr)
      data, name, elements = path_segments(path)
      value = lookup_path(data, elements)
      return value, name
    end

    def path_segments(path)
      case path.sexp_type
      when :segments
        data, name, elements = path.sexp_body
      when :undefined, :null
        elements = [path.sexp_type]
        name = elements.join
      else
        elements = [path[1]]
        name = elements.join
      end
      return data, name, elements
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

    def execute_in_context(callable, params = [], name:,
                           fn: nil, inverse: nil, block_params: 0, hash: nil)
      arity = callable.arity
      num_params = params.count
      arity = num_params + 2 if arity < 0
      raise_arity_error(arity, name, is_block: !fn.nil?) if arity > num_params + 2

      params = params.take(arity) if num_params > arity

      if arity > num_params
        options = Options.new(name: name,
                              fn: fn, inverse: inverse,
                              block_params: block_params, hash: hash,
                              data: @data)
        params.push options
      end
      params.unshift @helper_context.this if arity > num_params + 1
      @helper_context.instance_exec(*params, &callable)
    end

    def raise_arity_error(arity, name, is_block: false)
      expected = arity - 2
      identifier = is_block ? "##{name}" : name
      raise ArgumentError,
            "Expected #{expected} argument#{'s' if expected > 1} for #{identifier}"
    end

    def handle_if(context, *values, options)
      raise ArgumentError, "#if requires exactly one argument" unless values.size == 1

      value = values.first
      if value
        options.fn(context)
      else
        options.inverse(context)
      end
    end

    def handle_unless(context, *values, options)
      raise ArgumentError, "#unless requires exactly one argument" unless values.size == 1

      value = values.first
      options.fn(context) unless value
    end

    def handle_with(_context, *values, options)
      raise ArgumentError, "#with requires exactly one argument" unless values.size == 1

      value = values.first
      if value
        options.fn(value, block_params: [value])
      else
        options.inverse(value)
      end
    end

    def handle_each(_context, value, options)
      return unless value

      last = value.respond_to?(:length) ? value.length - 1 : -1
      @data.with_new_data do
        unless value.is_a? Hash
          value = value.each_with_index.lazy.map { |item, index| [index, item] }
        end
        items = value.each_with_index.map do |(key, item), index|
          @data.set_data(:key, key)
          @data.set_data(:index, index)
          @data.set_data(:first, index == 0)
          @data.set_data(:last, index == last)
          options.fn(item, block_params: [item, index])
        end
        items.to_a.join
      end
    end

    def handle_log(_context, value, _options)
      @log&.call(1, value)
      nil
    end

    def raise_helper_missing(name)
      raise "Missing helper: \"#{name}\""
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
  end
end
