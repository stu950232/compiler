lexer grammar mylexer;

options {
  language = Java;
}

/*----------------------*/
/*   Reserved Keywords  */
/*----------------------*/
INT_TYPE  : 'int';
CHAR_TYPE : 'char';
VOID_TYPE : 'void';
FLOAT_TYPE: 'float';
DOUBLE_TYPE:  'double';
CONST_TYPE: 'const';
UNSIGNED_TYPE  : 'unsigned';
SINGNED_TYPE  : 'signed';
BOOL_     : '_Bool';
SHORT_TYPE: 'short';
LONG_TYPE : 'long';
NULL_     : 'NULL';
STRUCT_TYPE: 'struct';
STATIC_TYPE:  'static';
ENUM_TYPE : 'enum';
TYPEDEF_  : 'typedef';
GOTO_     : 'goto';
UNION_TYPE: 'union';
WHILE_    : 'while';
FOR_      : 'for';
IF_       : 'if';
ELSE_IF_  : 'else if';
INCLUDE_  : 'include';
MAIN_     : 'main';
RETURN_   : 'return';
DEFINE_   : 'define';
SWITCH_   : 'switch';
CASE_     : 'case';
DEFAULT_  : 'default';
BREAK_    : 'break';
CONTINUE_ : 'continue';

/*PRINTF_  : 'printf';
SCANF_    : 'scanf';
FOPEN_    : 'fopen';
FSCANF_   : 'fscanf';
FCLOSE_   : 'fclose';
MALLOC_   : 'malloc';
SIZEOF_   : 'sizeof';
*/


/*----------------------*/
/*  Compound Operators  */
/*----------------------*/

EQ_OP : '==';
LE_OP : '<=';
GE_OP : '>=';
NE_OP : '!=';
PP_OP : '++';
MM_OP : '--'; 
ADDEQ_OP : '+=';
MINEQ_OP : '-=';
MULEQ_OP : '*=';
DIVEQ_OP : '/=';
ARR_OP : '->';
RSHIFT_OP : '<<';
LSHIFT_OP : '>>';
ADD_OP : '+';
MINUS_OP : '-';
MUL_OP : '*';
REMAIN_OP: '%';
DIVIDE_OP : '/';
XOR_OP : '^';
LE_ : '<';
GR_ : '>'; 
EQ: '=';
OR_ : '||';
AND_OP : '&&';
ADDERSS : '&';
NOT_ : '!';
COMPLEMENT : '~';
OR_OP : '|';
DOT : '.';


DEC_NUM : ('0' | ('1'..'9')(DIGIT)*);
/*HEADER: (LETTER)+'.h';*/
HEADER1: '<'(LETTER)(LETTER|DIGIT)*'.h''>';
HEADER2: '"'(LETTER)(LETTER|DIGIT)*'.h''"';

ID : (LETTER)(LETTER | DIGIT)*;
STRING : '\"'(.)*'\"';

FLOAT_NUM: FLOAT_NUM1 | FLOAT_NUM2 | FLOAT_NUM3;
fragment FLOAT_NUM1: (DIGIT)+'.'(DIGIT)*;
fragment FLOAT_NUM2: '.'(DIGIT)+;
fragment FLOAT_NUM3: (DIGIT)+;
 

/* Comments */
COMMENT1 : '//'(.)*'\n';
COMMENT2 : '/*' (options{greedy=false;}: .)* '*/';


NEW_LINE: '\n';

/*---------------*/
/*  punctuation  */
/*---------------*/
SEMICOLON : ';';
HASHTAG : '#';
COMMA: ',';
D_QUOTE : '"';
L_PAR : '(';
R_PAR : ')';
L_OB : '{';
R_OB : '}';
QUOTE : '\'';
L_BRACK : '[';
R_BRACK : ']';

fragment LETTER : 'a'..'z' | 'A'..'Z' | '_';
fragment DIGIT : '0'..'9';


WS  : (' '|'\r'|'\t')+
    ;
