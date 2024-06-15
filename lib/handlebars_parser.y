class HandlebarsParser
rule
start root

# %ebnf

# %%

# Based on src/handlebars.yy in handlebars-parser. Some extra rules were added
# because racc does not support certain things that jison supports.
#
# For example, the '*' to signify zero or more items. Rules that need this were
# generaly split into 'none | items', plus a new rule defining items as 'item |
# items item'.
#
# Similarly, an extra rule is needed to replace '?' signifyling zero or one of
# an item.

root
  : program
  ;

program
  : none
  | statements
  ;

# Extra rule needed for racc to parse list of one or more statements
statements
  : statement { result = s(:statements, val[0]) }
  | statements statement { result << val[1] }
  ;

statement
  : mustache
  | block
  | rawBlock
  | partial
  | partialBlock
  | content
  | COMMENT {
    result = s(:comment, strip_comment(val[0]), strip_flags(val[0], val[0]))
      .line(self.lexer.lineno)
  };

content
  : CONTENT {
    result = s(:content, val[0])
    result.line = self.lexer.lineno
  };

# Extra rule needed for racc to parse list of one or more pieces of content
contents:
  : content
  | contents content
  ;

rawBlock
  : openRawBlock contents END_RAW_BLOCK { yy.prepareRawBlock($1, $2, $3, self.lexer.lineno) }
  ;

openRawBlock
  : OPEN_RAW_BLOCK helperName exprs hash CLOSE_RAW_BLOCK { { path: $2, params: $3, hash: $4 } }
  ;

block
  : openBlock program inverseChain closeBlock { result = prepare_block(val[0], val[1], val[2], val[3], false) }
  | openInverse program optInverseAndProgram closeBlock {  result = prepare_block(val[0], val[1], val[2], val[3], true) }
  ;

openBlock
  : OPEN_BLOCK helperName exprs hash blockParams CLOSE { result = s(:open, val[1], val[2], val[3], val[4], strip_flags(val[0], val[5])) }
  ;

openInverse
  : OPEN_INVERSE helperName exprs hash blockParams CLOSE { result = s(:open, val[1], val[2], val[3], val[4], strip_flags(val[0], val[5])) }
  ;

openInverseChain
  : OPEN_INVERSE_CHAIN helperName exprs hash blockParams CLOSE { result = s(:open, val[1], val[2], val[3], val[4], strip_flags(val[0], val[5])) }
  ;

# Extra rule needed for racc to parse zero or one of inverseAndProgram
optInverseAndProgram
  : none
  | inverseAndProgram
  ;

inverseAndProgram
  : INVERSE program { result = s(:inverse, nil, val[1], strip_flags(val[0], val[0])) }
  ;

inverseChain
  : none
  | openInverseChain program inverseChain {
    block = prepare_block(val[0], val[1], val[2], nil, false)
    result = s(:inverse, nil, block)
  }
  | inverseAndProgram
  ;

closeBlock
  : OPEN_ENDBLOCK helperName CLOSE { result = s(:close, val[1], strip_flags(val[0], val[2])) }
  ;

mustache
  : OPEN expr exprs hash CLOSE { result = prepare_mustache(*val) }
  | OPEN_UNESCAPED expr exprs hash CLOSE_UNESCAPED { yy.prepareMustache($2, $3, $4, $1, yy.stripFlags($1, $5), self.lexer.lineno) }
  ;

partial
  : OPEN_PARTIAL expr exprs hash CLOSE {
    result = s(:partial, val[1], val[2], val[3], strip_flags(val[0], val[4]))
      .line(self.lexer.lineno)
  }
  ;

partialBlock
  : openPartialBlock program closeBlock { result = prepare_partial_block(*val) }
  ;

openPartialBlock
  : OPEN_PARTIAL_BLOCK expr exprs hash CLOSE { result = s(:open_partial, val[1], val[2], val[3], strip_flags(val[0], val[4])) }
  ;

expr
  : helperName
  | sexpr
  ;

# Extra rule needed to replace all cases of expr*
exprs:
  : none { result = s(:exprs) }
  | exprList
  ;

# Extra rule needed for racc to parse list of one or more exprs
exprList
  : expr { result = s(:exprs, val[0]) }
  | exprList expr { result.push(val[1]) }
  ;

sexpr
  : OPEN_SEXPR expr exprs hash CLOSE_SEXPR {
    result = s(:sub_expression, val[1], val[2], val[3]).line self.lexer.lineno
  };

hash
  : none
  | hashSegments { result = result.line(self.lexer.lineno) }
  ;

# Extra rule needed for racc to parse list of one or more hash segments
hashSegments
  hashSegment { result = s(:hash, val[0]) }
  | hashSegments hashSegment { result.push(val[1]) }
  ;

hashSegment
  : KEY_ASSIGN expr { result = s(:hash_pair, val[0], val[1]).line(self.lexer.lineno) }
  ;

blockParams
  : none
  | OPEN_BLOCK_PARAMS idSequence CLOSE_BLOCK_PARAMS { result = s(:block_params, *val[1]) }
  ;

# Extra rule needed for racc to parse list of one or more IDs
idSequence
  : ID { result = [id(val[0])] }
  | idSequence ID { result << id(val[1]) }
  ;

helperName
  : path
  | dataName
  | STRING { result = s(:string, val[0]).line(self.lexer.lineno) }
  | NUMBER { result = s(:number, process_number(val[0])).line(self.lexer.lineno) }
  | BOOLEAN { result = s(:boolean, val[0] == "true").line(self.lexer.lineno) }
  | UNDEFINED { result = s(:undefined).line(self.lexer.lineno) }
  | NULL { result = s(:null).line(self.lexer.lineno) }
  ;

dataName
  : DATA pathSegments { result = prepare_path(true, false, val[1], self.lexer.lineno) }
  ;

path
  : sexpr SEP pathSegments {
    # NOTE: Separator is always parsed as '/'
    result = prepare_path(false, false, [val[0], s(:sep, "/"), *val[2]], self.lexer.lineno)
  }
  | pathSegments { result = prepare_path(false, false, val[0], self.lexer.lineno) }
  ;

pathSegments
  : pathSegments SEP ID { result.push(s(:sep, val[1]), id(val[2])) }
  | ID { result = [id(val[0])] }
  ;

# Extra rule needed to define none, used in the added rules
none
  : { result = nil }
  ;

---- header
require "sexp"

---- inner
attr_reader :lexer

def parse(str)
  @lexer = HandlebarsLexer.new
  lexer.scan_setup(str)
  do_parse
end

def next_token
  lexer.next_token
end

# Use pure ruby racc imlementation for debugging
def do_parse
  _racc_do_parse_rb(_racc_setup(), false)
end

def process_number(str)
  if str =~ /\./
    str.to_f
  else
    str.to_i
  end
end

def strip_flags(start, finish)
  s(:strip, start[2] == "~", finish[-3] == "~")
end

def strip_comment(comment)
  comment.sub(/^\{\{~?!-?-?/, "").sub(/-?-?~?\}\}$/, "")
end

def id(val)
  if (match = /\A\[(.*)\]\Z/.match val)
    # TODO: Mark as having had square brackets
    s(:id, match[1])
  else
    s(:id, val)
  end
end

def prepare_path(data, sexpr, parts, loc)
  # TODO: Keep track of depth
  tail = []
  while parts.any?
    part, sep = parts.shift(2)

    if ["..", ".", "this"].include? part[1]
      unless tail.empty?
        path = tail.map { _1[1] }.join + part[1]
        raise ParseError, "Invalid path: #{path} - #{loc}:2"
      end
      next
    end

    tail << part
    tail << sep if sep
  end
  # TODO: Handle sexpr
  s(:path, data, *tail).line loc
end

def prepare_mustache(open, path, params, hash, close)
  decorator = /\*/.match? open
  type = decorator ? :directive : :mustache
  s(type, path, params, hash, strip_flags(open, close)).line(self.lexer.lineno)
end

def prepare_partial_block(open, program, close)
  _, name, params, hash, open_strip = *open
  _, close_name, close_strip = *close

  validated_close(name, close_name)

  s(:partial_block, name, params, hash, program, open_strip, close_strip)
    .line(self.lexer.lineno)
end

def prepare_block(open, program, inverse_chain, close, inverted)
  _, name, params, hash, block_params, open_strip = *open

  if close
    _, close_name, close_strip = *close
    validated_close(name, close_name)
  end

  # TODO: Get close_strip from inverse_chain if close is nil
  # TODO: Handle block decorator marker ('*')

  if inverted
    raise NotImplementedError if inverse_chain
    inverse_chain = s(:inverse, block_params, program)
    program = nil
  else
    program = s(:program, block_params, program)
  end

  s(:block, name, params, hash, program, inverse_chain, open_strip, close_strip)
    .line(self.lexer.lineno)
end

def validated_close(name, close_name)
  unless name == close_name
    raise ParseError, "#{name[2][1]} doesn't match #{close_name[2][1]}"
  end
end

def on_error(t, val, vstack)
  raise ParseError, sprintf("Parse error on line %i on value %s (%s) at %s",
      self.lexer.lineno, val.inspect, token_to_str(t) || '?', vstack.inspect)
end
