class HandlebarsLexer
%x mu emu com raw

inner

    def do_parse
      result = []
      while token = next_token
        result << token
      end
      result
    end

    def handle_stringescape(str, delimiter)
      case delimiter
      when '"', "'"
        str[1..-2]
      else
        raise NotImplementedError
      end
    end

macro
LEFT_STRIP    ~
RIGHT_STRIP   ~

LOOKAHEAD           [=~}\s\/.)|]
LIT_LOOKAHEAD       [~}\s)]

# ID is the inverse of control characters.
# Control characters ranges:
#   [\s]          Whitespace
#   [!"#%-,\./]   !, ", #, %, &, ', (, ), *, +, ,, ., /,  Exceptions in range: $, -
#   [;->@]        ;, <, =, >, @,                          Exceptions in range: :, ?
#   [\[-\^`]      [, \, ], ^, `,                          Exceptions in range: _
#   [\{-~]        {, |, }, ~
ID    [^\s!"\#%-,\.\/;->@\[-\^`\{-~]+(?={LOOKAHEAD})

rule

\n                               { [:CONTENT, text] }
[^\x00\n]*?(?={{)                {
                                   if(text.slice(-2, 2) === "\\\\")
                                     text = text[0..-2]
                                     @state = :MU
                                   elsif(text.slice(-1) === "\\")
                                     text = text[0..-2]
                                     @state = :EMU
                                   else
                                     @state = :MU
                                   end
                                   [:CONTENT, text] unless(text.empty?)
                                 }

[^\x00\n]+                       { [:CONTENT, text] }

# consume escaped mustache
:EMU {{                          { @state = nil; [:CONTENT, text] }

# End of raw block if delimiter text matches opening text
:RAW {{{{\/[^\s!"#%-,\.\/;->@\[-\^`\{-~]+}}}} {
                                  ending_delimiter = text[5...-4]
                                  if ending_delimiter == @raw_delimiter
                                    @state = nil
                                    [:END_RAW_BLOCK, ending_delimiter]
                                  else
                                    [:CONTENT, text]
                                  end
                                 }
:RAW [^\x00]+?(?={{{{)           { [:CONTENT, text] }

:COM [\s\S]*?\-\-{RIGHT_STRIP}?}}   { @state = nil; [:COMMENT, text] }

:MU \(                           { [:OPEN_SEXPR, text] }
:MU \)                           { [:CLOSE_SEXPR, text] }

:MU {{{{                         {
                                   @expect_raw_block_id = true
                                   [:OPEN_RAW_BLOCK, text]
                                 }
:MU }}}}                         {
                                   @state = :RAW
                                   [:CLOSE_RAW_BLOCK, text]
                                 }
:MU {{{LEFT_STRIP}?>             { [:OPEN_PARTIAL, text] }
:MU {{{LEFT_STRIP}?#>            { [:OPEN_PARTIAL_BLOCK, text] }
:MU {{{LEFT_STRIP}?#\*?          { [:OPEN_BLOCK, text] }
:MU {{{LEFT_STRIP}?\/            { [:OPEN_ENDBLOCK, text] }
:MU {{{LEFT_STRIP}?\^\s*{RIGHT_STRIP}?}}      { @state = nil; [:INVERSE, text] }
:MU {{{LEFT_STRIP}?\s*else\s*{RIGHT_STRIP}?}} { @state = nil; [:INVERSE, text] }
:MU {{{LEFT_STRIP}?\^            { [:OPEN_INVERSE, text] }
:MU {{{LEFT_STRIP}?\s*else       { [:OPEN_INVERSE_CHAIN, text] }
:MU {{{LEFT_STRIP}?{             { [:OPEN_UNESCAPED, text] }
:MU {{{LEFT_STRIP}?&             { [:OPEN, text] }
:MU {{{LEFT_STRIP}?!--           { @state = :COM; [:COMMENT, text] }
:MU {{{LEFT_STRIP}?![\s\S]*?}}   { @state = nil; [:COMMENT, text] }
:MU {{{LEFT_STRIP}?\*?           { [:OPEN, text] }

:MU =                            { [:EQUALS, text] }
:MU \.\.                         { [:ID, text] }
:MU \.(?={LOOKAHEAD})            { [:ID, text] }
:MU [\/.]                        { [:SEP, text] }
:MU \s+                          // ignore whitespace
:MU }{RIGHT_STRIP}?}}            { @state = nil; [:CLOSE_UNESCAPED, text] }
:MU {RIGHT_STRIP}?}}             { @state = nil; [:CLOSE, text] }
:MU "(\\"|[^"])*"                { text = handle_stringescape(text, '"'); [:STRING, text] }
:MU '(\\'|[^'])*'                { text = handle_stringescape(text, "'"); [:STRING, text] }
:MU @                            { [:DATA, text] }
:MU true(?={LIT_LOOKAHEAD})      { [:BOOLEAN, text] }
:MU false(?={LIT_LOOKAHEAD})     { [:BOOLEAN, text] }
:MU undefined(?={LIT_LOOKAHEAD}) { [:UNDEFINED, text] }
:MU null(?={LIT_LOOKAHEAD})      { [:NULL, text] }
:MU \-?[0-9]+(?:\.[0-9]+)?(?={LIT_LOOKAHEAD}) { [:NUMBER, text] }
:MU as\s+\|                      { [:OPEN_BLOCK_PARAMS, text] }
:MU \|                           { [:CLOSE_BLOCK_PARAMS, text] }

:MU {ID}=                        { [:KEY_ASSIGN, text[0..-2]] }
:MU {ID}                         {
                                   if @expect_raw_block_id
                                     @raw_delimiter = text
                                     @expect_raw_block_id = false
                                   end
                                   [:ID, text]
                                 }

:MU \[(\\\]|[^\]])*\]            { text = text.gsub(/\\([\\\]])/, '\1'); [:ID, text] }
:MU .                            { [:INVALID, text] }

<INITIAL,mu><<EOF>>              { [:EOF, text] }
end
