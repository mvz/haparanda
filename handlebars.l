class HandlebarsLexer
%x mu emu com raw

%{

function strip(start, end) {
  return yytext = yytext.substring(start, yyleng - end + start);
}

%}

macro
LEFT_STRIP    "~"
RIGHT_STRIP   "~"

LOOKAHEAD           [=~}\s\/.)|]
LITERAL_LOOKAHEAD   [~}\s)]

# ID is the inverse of control characters.
# Control characters ranges:
#   [\s]          Whitespace
#   [!"#%-,\./]   !, ", #, %, &, ', (, ), *, +, ,, ., /,  Exceptions in range: $, -
#   [;->@]        ;, <, =, >, @,                          Exceptions in range: :, ?
#   [\[-\^`]      [, \, ], ^, `,                          Exceptions in range: _
#   [\{-~]        {, |, }, ~
ID    [^\s!"#%-,\.\/;->@\[-\^`\{-~]+/{LOOKAHEAD}

rule

[^\x00]*?(?:{{)                {
                                   if(yytext.slice(-2) === "\\\\")
                                     strip(0,1);
                                     state = :MU
                                   elsif(yytext.slice(-1) === "\\")
                                     strip(0,1);
                                     state = :EMU
                                   else
                                     state = :MU
                                   end
                                   'CONTENT' if(yytext)
                                 }

[^\x00]+                         { 'CONTENT' }

# consume escaped mustache
:EMU {{                          {
                                   state = nil
                                   'CONTENT'
                                 }

# nested raw block will create stacked 'raw' condition
:RAW "{{{{"/[^/]                 { state = :RAW; 'CONTENT' }
:RAW "{{{{/"[^\s!"#%-,\.\/;->@\[-\^`\{-~]+/[=}\s\/.]"}}}}" {
                                  this.popState();
                                  // Should be using `this.topState()` below, but it currently
                                  // returns the second top instead of the first top. Opened an
                                  // issue about it at https://github.com/zaach/jison/issues/291
                                  if (this.conditionStack[this.conditionStack.length-1] === 'raw') {
                                    'CONTENT';
                                  } else {
                                    strip(5, 9);
                                    'END_RAW_BLOCK';
                                  }
                                 }
:RAW [^\x00]+?/("{{{{")          { 'CONTENT' }

:COM [\s\S]*?"--"{RIGHT_STRIP}?"}}" {
  this.popState();
  'COMMENT';
}

:MU "("                          { 'OPEN_SEXPR' }
:MU ")"                          { 'CLOSE_SEXPR' }

:MU "{{{{"                       { 'OPEN_RAW_BLOCK'; }
:MU "}}}}"                       {
                                  this.popState();
                                  state = :RAW
                                  'CLOSE_RAW_BLOCK';
                                 }
:MU "{{"{LEFT_STRIP}?">"         { 'OPEN_PARTIAL' }
:MU "{{"{LEFT_STRIP}?"#>"        { 'OPEN_PARTIAL_BLOCK' }
:MU "{{"{LEFT_STRIP}?"#""*"?     { 'OPEN_BLOCK' }
:MU "{{"{LEFT_STRIP}?"/"         { 'OPEN_ENDBLOCK' }
:MU "{{"{LEFT_STRIP}?"^"\s*{RIGHT_STRIP}?"}}"       { this.popState(); 'INVERSE'; }
:MU "{{"{LEFT_STRIP}?\s*"else"\s*{RIGHT_STRIP}?"}}" { this.popState(); 'INVERSE'; }
:MU "{{"{LEFT_STRIP}?"^"         { 'OPEN_INVERSE' }
:MU "{{"{LEFT_STRIP}?\s*"else"   { 'OPEN_INVERSE_CHAIN' }
:MU "{{"{LEFT_STRIP}?"{"         { 'OPEN_UNESCAPED' }
:MU "{{"{LEFT_STRIP}?"&"         { 'OPEN' }
:MU "{{"{LEFT_STRIP}?"!--" {
  this.unput(yytext);
  this.popState();
  state = :COM
}
:MU "{{"{LEFT_STRIP}?"!"[\s\S]*?"}}" {
  this.popState();
  'COMMENT';
}
:MU "{{"{LEFT_STRIP}?"*"?        { 'OPEN' }

:MU "="                          { 'EQUALS' }
:MU ".."                         { 'ID' }
:MU "."/{LOOKAHEAD}              { 'ID' }
:MU [\/.]                        { 'SEP' }
:MU \s+                          // ignore whitespace
:MU "}"{RIGHT_STRIP}?"}}"        { this.popState(); 'CLOSE_UNESCAPED'; }
:MU {RIGHT_STRIP}?"}}"           { this.popState(); 'CLOSE'; }
:MU '"'("\\"["]|[^"])*'"'        { yytext = strip(1,2).replace(/\\"/g,'"'); 'STRING'; }
:MU "'"("\\"[']|[^'])*"'"        { yytext = strip(1,2).replace(/\\'/g,"'"); 'STRING'; }
:MU "@"                          { 'DATA' }
:MU "true"/{LITERAL_LOOKAHEAD}   { 'BOOLEAN'; }
:MU "false"/{LITERAL_LOOKAHEAD}  { 'BOOLEAN'; }
:MU "undefined"/{LITERAL_LOOKAHEAD} { 'UNDEFINED'; }
:MU "null"/{LITERAL_LOOKAHEAD}   { 'NULL'; }
:MU \-?[0-9]+(?:\.[0-9]+)?/{LITERAL_LOOKAHEAD} { 'NUMBER'; }
:MU "as"\s+"|"                   { 'OPEN_BLOCK_PARAMS' }
:MU "|"                          { 'CLOSE_BLOCK_PARAMS' }

:MU {ID}                         { 'ID' }

:MU '['('\\]'|[^\]])*']'         { yytext = yytext.replace(/\\([\\\]])/g,'$1'); 'ID'; }
:MU .                            { 'INVALID' }

<INITIAL,mu><<EOF>>              { 'EOF' }
end
