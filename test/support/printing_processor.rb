# frozen_string_literal: true

require "sexp_processor"

class PrintingProcessor < SexpProcessor # rubocop:disable Metrics/ClassLength
  def initialize
    super

    self.require_empty = false
  end

  def print(expr)
    result = process(expr)
    raise "Unexpected result #{result}" unless result.sexp_type == :print

    result.sexp_body[0]
  end

  def process_root(expr)
    _, statements = expr
    process(statements)
  end

  def process_statements(expr)
    printed = print_all(expr.sexp_body)
    s(:print, printed.join)
  end

  def process_content(expr)
    _, contents = expr
    s(:print, "CONTENT[ '#{contents}' ]\n")
  end

  def process_partial(expr)
    _, name, params, hash, = expr
    args = [params, hash].compact.map { print _1 }.join(" ").strip
    name = partial_name(name)
    if args.empty?
      s(:print, "{{> PARTIAL:#{name} }}\n")
    else
      s(:print, "{{> PARTIAL:#{name} #{args} }}\n")
    end
  end

  def process_partial_block(expr)
    _, name, params, hash, program, = expr
    args = [params, hash].compact.map { print _1 }.join(" ").strip
    name = partial_name(name)
    program = print program
    if args.empty?
      s(:print, "{{> PARTIAL BLOCK:#{name} PROGRAM:\n  #{program} }}\n")
    else
      s(:print, "{{> PARTIAL BLOCK:#{name} #{args} PROGRAM:\n  #{program} }}\n")
    end
  end

  def process_block(expr)
    _, name, params, hash, program, inverse_chain, = expr
    args = [params, hash].compact.map { print _1 }.join(" ").strip
    name = print(name)
    program = print(program).gsub(/^/, "  ") if program
    inverse_chain = print(inverse_chain).gsub(/^/, "  ") if inverse_chain
    s(:print, "BLOCK:\n  #{name} [#{args}]\n#{program}#{inverse_chain}")
  end

  def process_directive_block(expr)
    _, name, params, hash, program, inverse_chain, = expr
    args = [params, hash].compact.map { print _1 }.join(" ").strip
    name = print(name)
    program = print(program).gsub(/^/, "  ") if program
    inverse_chain = print(inverse_chain).gsub(/^/, "  ") if inverse_chain
    s(:print, "DIRECTIVE BLOCK:\n  #{name} [#{args}]\n#{program}#{inverse_chain}")
  end

  def process_program(expr)
    _, params, program, = expr
    params = print(params).gsub(/^/, "  ") if params
    program = print(program).gsub(/^/, "  ") if program
    s(:print, "PROGRAM:\n#{params}#{program}")
  end

  def process_inverse(expr)
    _, block_params, program, = expr
    block_params = print(block_params).gsub(/^/, "  ") if block_params
    program = print(program).gsub(/^/, "  ") if program
    s(:print, "{{^}}\n#{block_params}#{program}")
  end

  def process_mustache(expr)
    sexp_type, val, params, hash, _escaped, _strip = expr
    params = "[#{print params}]"
    hash = print hash if hash
    args = [params, hash].compact.join(" ")
    val = print(val)
    directive = "DIRECTIVE " if sexp_type == :directive
    s(:print, "{{ #{directive}#{val} #{args} }}\n")
  end

  alias process_directive process_mustache

  def process_comment(expr)
    _, comment, = expr
    s(:print, "{{! '#{comment}' }}\n")
  end

  def process_number(expr)
    _, val = expr
    s(:print, "NUMBER{#{val}}")
  end

  def process_boolean(expr)
    _, val = expr
    s(:print, "BOOLEAN{#{val}}")
  end

  def process_string(expr)
    _, val = expr
    s(:print, val.inspect)
  end

  def process_id(expr)
    _, id = expr
    s(:print, id)
  end

  def process_sep(expr)
    _, sep = expr
    s(:print, sep)
  end

  def process_path(expr)
    _, data, *segments = expr
    segments = path_segments(segments)
    s(:print, "#{'@' if data}PATH:#{segments.join}")
  end

  def process_sub_expression(expr)
    _, path, params, hash, = expr
    params = "[#{print params}]"
    hash = print hash if hash
    args = [params, hash].compact.join(" ")
    s(:print, "#{print(path)} #{args}")
  end

  def process_exprs(expr)
    printed_vals = print_all(expr.sexp_body)
    s(:print, printed_vals.join(", "))
  end

  def process_block_params(expr)
    params = print_all(expr.sexp_body)
    s(:print, "BLOCK PARAMS: [ #{params.join(' ')} ]\n")
  end

  def process_undefined(_expr)
    s(:print, "UNDEFINED")
  end

  def process_null(_expr)
    s(:print, "NULL")
  end

  def process_hash(expr)
    printed_pairs = print_all(expr.sexp_body)
    s(:print, "HASH{#{printed_pairs.join(', ')}}")
  end

  def process_hash_pair(expr)
    _, key, val = expr
    val = print val
    s(:print, "#{key}=#{val}")
  end

  def shift_all(expr)
    result = []
    result << expr.shift while expr.any?
    result
  end

  def print_all(expr)
    result = []
    result << print(expr.shift) while expr.any?
    result
  end

  def path_segments(segments)
    segments.shift(2) while ["..", ".", "this"].include? segments.dig(0, 1)
    segments.map do |seg|
      case seg.sexp_type
      when :sub_expression
        "[#{print(seg)}]"
      else
        print(seg)
      end
    end
  end

  def partial_name(expr)
    case expr.sexp_type
    when :path
      print_all(expr[2..]).join
    else
      expr[1]
    end
  end
end
