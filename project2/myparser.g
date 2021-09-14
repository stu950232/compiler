grammar myparser;

options {
   language = Java;
}

@header {
    // import packages here.
}

@members {
    boolean TRACEON = true;
}

program:VOID MAIN '(' ')' '{' declarations statements '}'
        {if (TRACEON) System.out.println("VOID MAIN () {declarations statements}");};

declarations:type Identifier ';' declarations
             { if (TRACEON) System.out.println("declarations: type Identifier : declarations"); }
            | type Identifier '=' number ';' declarations
             { if (TRACEON) System.out.println("declarations: type Identifier : declarations"); }
           | { if (TRACEON) System.out.println("declarations: ");} ;

type:INT { if (TRACEON) System.out.println("type: INT"); }
    | CHAR {if (TRACEON) System.out.println("type: CHAR"); }
    | VOID {if (TRACEON) System.out.println("type: VOID"); }
   | FLOAT {if (TRACEON) System.out.println("type: FLOAT"); }
   | DOUBLE {if (TRACEON) System.out.println("type: DOUBLE"); }
   | UNSIGNED {if (TRACEON) System.out.println("type: UNSIGNED"); }
   | SINGNED {if (TRACEON) System.out.println("type: SINGNED"); }
   | BOOL {if (TRACEON) System.out.println("type: BOOL"); }
   | SHORT {if (TRACEON) System.out.println("type: SHORT"); }
   | LONG {if (TRACEON) System.out.println("type: LONG"); }
   | NULL_ {if (TRACEON) System.out.println("type: NULL"); };

statements:statement statements
        |;

arith_expression: multExpr
                  ( '+' multExpr {if (TRACEON) System.out.println("add arith expression");}
				  | '-' multExpr {if (TRACEON) System.out.println("minus arith expression");}
				  )*
                  ;
condtional_judgment: 
            Identifier {if (TRACEON) System.out.println("condtional is Identifier");}
            | number {if (TRACEON) System.out.println("condtional is number");}
            | Identifier conditonal_op condtional_judgment {if (TRACEON) System.out.println("Identifier <=,>=,>,<,!= condtional_judgment");}
            | 
            ;

multExpr: signExpr
          ( '*' signExpr {if (TRACEON) System.out.println("Multiply arith expression");}
          | '/' signExpr {if (TRACEON) System.out.println("division arith expression");}
		  )*
		  ;

signExpr: primaryExpr
        | '-' primaryExpr {if (TRACEON) System.out.println("negative primaryExpr");}
		;
		  
primaryExpr: number {if (TRACEON) System.out.println("primaryExpr is number");}
           | Identifier {if (TRACEON) System.out.println("primaryExpr is Identifier");}
		   | '(' arith_expression ')' {if (TRACEON) System.out.println("primaryExpr is  arith_expression ");}
           ;

statement: Identifier '=' arith_expression ';' {if (TRACEON) System.out.println("Identifier equals to arith_expression  ");}
         | IF '(' condtional_judgment ')' if_then_statements {if (TRACEON) System.out.println("IF_THEN");}
         | ELSE else_statements {if (TRACEON) System.out.println("ELSE");}
         | print_fuction
         | while_loop
         | for_loop
         | Identifier (PP_OP | MM_OP ) ';' {if (TRACEON) System.out.println("Identifier ++,--");}
         | Identifier (ADDEQ_OP | MINEQ_OP | MULEQ_OP | DIVEQ_OP) (Identifier | number) ';'{if (TRACEON) System.out.println("Identifier +=,-=,*=,/= Identifier | number");}
         | CONTINUE
         | BREAK
		 ;
for_loop:
        FOR '(' statement condtional_judgment ';' Identifier (PP_OP | MM_OP ) ')' for_statements {if (TRACEON) System.out.println("FOR LOOP");};

while_statements: statement
                | '{' statements '}' 
				  ;
for_statements: statement
                |'{' statements '}'
				  ;

while_loop: WHILE '(' condtional_judgment ')' while_statements {if (TRACEON) System.out.println("WHILE LOOP");};





if_then_statements: statement 
                  | '{' statements '}' 
				  ;
else_statements: statement 
                  | '{' statements '}' 
				  ;


print_fuction: PRINTF_ '(' STRING (',' Identifier)* ')'  ';' { if (TRACEON) System.out.println("PRINTF FUNCTION"); };

/*print_statments: STRING (',' Identifier)*;*/



number
    :   Integer_constant {if (TRACEON) System.out.println("Integer_constant"); }
    |   Floating_point_constant {if (TRACEON) System.out.println(" Floating_point_constant"); };

conditonal_op: EQ_OP
    | LE_OP
    | NE_OP
    | GE_OP
    | LE_
    | GR_
    ;




		   
/* description of the tokens */
FLOAT:'float';
DOUBLE:  'double';
UNSIGNED  : 'unsigned';
SINGNED  : 'signed';
BOOL     : '_Bool';
SHORT: 'short';
LONG: 'long';
NULL_: 'NULL';
INT:'int';
CHAR: 'char';
MAIN: 'main';
VOID: 'void';
IF: 'if';
ELSE: 'else';
BREAK: 'break';
CONTINUE: 'continue';
RETURN: 'return';
PRINTF_: 'printf';
WHILE: 'while';
FOR: 'for';

EQ_OP : '==';
LE_OP : '<=';
GE_OP : '>=';
NE_OP : '!=';
LE_ : '<';
GR_ : '>'; 
OR_OP : '|';
AND_OP : '&&';
PP_OP : '++';
MM_OP : '--'; 
ADDEQ_OP : '+=';
MINEQ_OP : '-=';
MULEQ_OP : '*=';
DIVEQ_OP : '/=';
/* A number: can be an integer value, or a decimal value */


Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:'0'..'9'+;
Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;
STRING : '\"'(.)*'\"';

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
COMMENT:'/*' .* '*/' {$channel=HIDDEN;};
