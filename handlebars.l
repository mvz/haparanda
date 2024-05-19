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

[^\x00]*?/("{{")                {
                                   if(yytext.slice(-2) === "\\\\") {
                                     strip(0,1);
                                     this.begin("mu");
                                   } else if(yytext.slice(-1) === "\\") {
                                     strip(0,1);
                                     this.begin("emu");
                                   } else {
                                     this.begin("mu");
                                   }
                                   if(yytext) return 'CONTENT';
                                 }

[^\x00]+                         return 'CONTENT';

// marks CONTENT up to the next mustache or escaped mustache
:EMU [^\x00]{2,}?/("{{"|"\\{{"|"\\\\{{"|<<EOF>>) {
                                   this.popState();
                                   return 'CONTENT';
                                 }

// nested raw block will create stacked 'raw' condition
:RAW "{{{{"/[^/]                 this.begin('raw'); return 'CONTENT';
:RAW "{{{{/"[^\s!"#%-,\.\/;->@\[-\^`\{-~]+/[=}\s\/.]"}}}}" {
                                  this.popState();
                                  // Should be using `this.topState()` below, but it currently
                                  // returns the second top instead of the first top. Opened an
                                  // issue about it at https://github.com/zaach/jison/issues/291
                                  if (this.conditionStack[this.conditionStack.length-1] === 'raw') {
                                    return 'CONTENT';
                                  } else {
                                    strip(5, 9);
                                    return 'END_RAW_BLOCK';
                                  }
                                 }
:RAW [^\x00]+?/("{{{{")          { return 'CONTENT'; }

:COM [\s\S]*?"--"{RIGHT_STRIP}?"}}" {
  this.popState();
  return 'COMMENT';
}

:MU "("                          return 'OPEN_SEXPR';
:MU ")"                          return 'CLOSE_SEXPR';

:MU "{{{{"                       { return 'OPEN_RAW_BLOCK'; }
:MU "}}}}"                       {
                                  this.popState();
                                  this.begin('raw');
                                  return 'CLOSE_RAW_BLOCK';
                                 }
:MU "{{"{LEFT_STRIP}?">"         return 'OPEN_PARTIAL';
:MU "{{"{LEFT_STRIP}?"#>"        return 'OPEN_PARTIAL_BLOCK';
:MU "{{"{LEFT_STRIP}?"#""*"?     return 'OPEN_BLOCK';
:MU "{{"{LEFT_STRIP}?"/"         return 'OPEN_ENDBLOCK';
:MU "{{"{LEFT_STRIP}?"^"\s*{RIGHT_STRIP}?"}}"        this.popState(); return 'INVERSE';
:MU "{{"{LEFT_STRIP}?\s*"else"\s*{RIGHT_STRIP}?"}}"  this.popState(); return 'INVERSE';
:MU "{{"{LEFT_STRIP}?"^"         return 'OPEN_INVERSE';
:MU "{{"{LEFT_STRIP}?\s*"else"   return 'OPEN_INVERSE_CHAIN';
:MU "{{"{LEFT_STRIP}?"{"         return 'OPEN_UNESCAPED';
:MU "{{"{LEFT_STRIP}?"&"         return 'OPEN';
:MU "{{"{LEFT_STRIP}?"!--" {
  this.unput(yytext);
  this.popState();
  this.begin('com');
}
:MU "{{"{LEFT_STRIP}?"!"[\s\S]*?"}}" {
  this.popState();
  return 'COMMENT';
}
:MU "{{"{LEFT_STRIP}?"*"?        return 'OPEN';

:MU "="                          return 'EQUALS';
:MU ".."                         return 'ID';
:MU "."/{LOOKAHEAD}              return 'ID';
:MU [\/.]                        return 'SEP';
:MU \s+                          // ignore whitespace
:MU "}"{RIGHT_STRIP}?"}}"        this.popState(); return 'CLOSE_UNESCAPED';
:MU {RIGHT_STRIP}?"}}"           this.popState(); return 'CLOSE';
:MU '"'("\\"["]|[^"])*'"'        yytext = strip(1,2).replace(/\\"/g,'"'); return 'STRING';
:MU "'"("\\"[']|[^'])*"'"        yytext = strip(1,2).replace(/\\'/g,"'"); return 'STRING';
:MU "@"                          return 'DATA';
:MU "true"/{LITERAL_LOOKAHEAD}   return 'BOOLEAN';
:MU "false"/{LITERAL_LOOKAHEAD}  return 'BOOLEAN';
:MU "undefined"/{LITERAL_LOOKAHEAD} return 'UNDEFINED';
:MU "null"/{LITERAL_LOOKAHEAD}   return 'NULL';
:MU \-?[0-9]+(?:\.[0-9]+)?/{LITERAL_LOOKAHEAD} return 'NUMBER';
:MU "as"\s+"|"                   return 'OPEN_BLOCK_PARAMS';
:MU "|"                          return 'CLOSE_BLOCK_PARAMS';

:MU {ID}                         return 'ID';

:MU '['('\\]'|[^\]])*']'         yytext = yytext.replace(/\\([\\\]])/g,'$1'); return 'ID';
:MU .                            return 'INVALID';

<INITIAL,mu><<EOF>>              return 'EOF';
end
