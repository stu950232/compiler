grammar myChecker;

@header {
    // import packages here.
    import java.util.HashMap;
}

@members {
    boolean TRACEON = false;
    HashMap<String,Integer> symtab = new HashMap<String,Integer>();

    
    public enum TypeInfo { 
		Integer,
		Float,
		Unknown,
		Bool,
		No_Exist,
		Error;
    }
    

    /*
    attr_type:
       1 => integer,
       2 => float,
       -1 => do not exist,
       -2 => error
    */	   
}

program
	: VOID MAIN '(' ')' '{' declarations* statements '}'
        { if (TRACEON) System.out.println("VOID MAIN () {declarations statements}"); }
	;

declarations
	: type Identifier ';' 
      {
	     if (TRACEON) System.out.println("declarations: type Identifier : declarations");
	   
  	     if (symtab.containsKey($Identifier.text)) {
		   System.out.println("Error: " + 
				              $Identifier.getLine() + 
							  ": Redeclared identifier.");
	     } else {
		   /* Add ID and its attr_type into the symbol table. */
		   symtab.put($Identifier.text, $type.attr_type);	   
	     }
	   }
	 
	;

type returns [int attr_type]
	:INT    { if (TRACEON) System.out.println("type: INT"); TypeInfo att = TypeInfo.Integer; $attr_type =att.ordinal(); }
	| FLOAT { if (TRACEON) System.out.println("type: FLOAT"); TypeInfo att = TypeInfo.Float; $attr_type = att.ordinal(); }
	| BOOL { if (TRACEON) System.out.println("type: BOOL"); TypeInfo att = TypeInfo.Bool; $attr_type = att.ordinal(); }
	;

statements
	:statement statements
	|;



arith_expression returns [int attr_type]
	: a = multExpr { $attr_type = $a.attr_type; }
      ( '+' b = multExpr
	    { 
		  if (TRACEON) System.out.println("add arith expression");

		  if ($a.attr_type != $b.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() +
						         ": Type mismatch for the operator + in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
        }
	  | '-' c = multExpr
 	     	{ 
		  if (TRACEON) System.out.println("sub arith expression");

		  if ($a.attr_type != $c.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() +
						         ": Type mismatch for the operator - in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
		} 
       
	  | PP_OP {if (TRACEON) System.out.println("plus plus expression");}
	  | MM_OP {if (TRACEON) System.out.println("minus minus expression");}
	)*
        ;

multExpr returns [int attr_type]
	: a = signExpr { $attr_type = $a.attr_type; }
      ( '*' b = signExpr
	  	{
		  if (TRACEON) System.out.println("multiply arith expression");

		  if ($a.attr_type != $b.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() +
						         ": Type mismatch for the operator * in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }

		}
      | '/' c = signExpr
	  	{
		  if (TRACEON) System.out.println("division arith expression");

		  if ($a.attr_type != $c.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() +
						         ": Type mismatch for the operator / in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
			}
		}
	  )*
	;

signExpr returns [int attr_type]
	: primaryExpr { $attr_type = $primaryExpr.attr_type; }
	| '-' primaryExpr { $attr_type = $primaryExpr.attr_type; }
	;
		  
primaryExpr returns [int attr_type] 
	: Integer_constant        { TypeInfo att = TypeInfo.Integer; $attr_type =att.ordinal(); }
	| Floating_point_constant { TypeInfo att = TypeInfo.Float; $attr_type = att.ordinal(); }
	| Identifier {
        if (symtab.containsKey($Identifier.text)) {
	         $attr_type = symtab.get($Identifier.text);
	    }else {
		   System.out.println("Error: " + 
				              $Identifier.getLine() +
							": Undeclared identifier.");
	       TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
	    }
    }
	| '(' arith_expression ')' { $attr_type = $arith_expression.attr_type; }
    ;

condtional_judgment returns [int attr_type]
	: a = arith_expression { $attr_type = $a.attr_type; }
    ( EQ_OP b = arith_expression
 	    { 
		  if (TRACEON) System.out.println("equivalent expression");

		  if ($a.attr_type != $b.attr_type) {
		      System.out.println("Error: " + 
				                 $a.start.getLine() + 
						         ": Type mismatch for the operator == in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
		  else{ TypeInfo att = TypeInfo.Bool; $attr_type = att.ordinal(); }
		}
      | NE_OP c = arith_expression
 	    { 
	      if (TRACEON) System.out.println("inequivalent expression");

		  if ($a.attr_type != $c.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() + 
						         ": Type mismatch for the operator != in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
		  else{ TypeInfo att = TypeInfo.Bool; $attr_type = att.ordinal(); }
		}

	  | LE_OP d = arith_expression
 	    { 
		  if (TRACEON) System.out.println("smaller than or equal to expression");

		  if ($a.attr_type != $d.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() + 
						         ": Type mismatch for the operator <= in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
		  else{ TypeInfo att = TypeInfo.Bool; $attr_type = att.ordinal(); }
		}
	  | GE_OP e = arith_expression
 	    { 
		  if (TRACEON) System.out.println("bigger than or equal to expression");

		  if ($a.attr_type != $e.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() + 
						         ": Type mismatch for the operator >= in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
		  else{ TypeInfo att = TypeInfo.Bool; $attr_type = att.ordinal(); }
		}
      | LE_ f = arith_expression
 	    { 
		  if (TRACEON) System.out.println("smaller than expression");

		  if ($a.attr_type != $f.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() + 
						         ": Type mismatch for the operator < in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
		  else{ TypeInfo att = TypeInfo.Bool; $attr_type = att.ordinal(); }
		}
      | GR_ g = arith_expression
 	    { 
		  if (TRACEON) System.out.println("bigger than expression");

		  if ($a.attr_type != $g.attr_type) {
			  System.out.println("Error: " + 
				                 $a.start.getLine() + 
						         ": Type mismatch for the operator > in an expression.");
		      TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
		  }
		  else{ TypeInfo att = TypeInfo.Bool; $attr_type = att.ordinal(); }
		}
      
	)*
    ;

statement returns [int attr_type]
	: Identifier '=' arith_expression ';'
	  {
	    if (TRACEON) System.out.println("assignment statement");

	    if (symtab.containsKey($Identifier.text)) {
	       $attr_type = symtab.get($Identifier.text);
	    } else {
            System.out.println("Error: " + 
				              $arith_expression.start.getLine() +
							  ": Undeclared identifier.");
	       TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
	       return $attr_type;
	    }
		
	    if ($attr_type != $arith_expression.attr_type) {
           	System.out.println("Error: " + 
				              $arith_expression.start.getLine() +
						      ": Type mismatch for the two silde operands in an assignment statement.");
		    TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
        }
	  }
	| print_fuction
	| identifier_double

	| IF '(' condtional_judgment ')' if_then_statements 
	  {
	    if (TRACEON) System.out.println("if statement");
		
	    if ($condtional_judgment.attr_type != 3) {
          System.out.println("Error: " + 
				              $condtional_judgment.start.getLine() +
						      ": Type error for the condtional_judgment.");
		  TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
        }
	  }
		
    | ELSE else_statements {if (TRACEON) System.out.println("else statement");}
    | FOR '(' statement condtional_judgment ';' arith_expression ')'  for_statements 
	  {
	    if (TRACEON) System.out.println("for statement");
		
		if ($condtional_judgment.attr_type != 3) {
           		System.out.println("Error: " + 
				              $condtional_judgment.start.getLine() +
						      ": Type error for the condtional_judgment.");
				TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
        }
	  }

    | WHILE '(' condtional_judgment ')' while_statements 
	  {
		if (TRACEON) System.out.println("while statement");

		if ($condtional_judgment.attr_type != 3) {
           		System.out.println("Error: " + 
				              $condtional_judgment.start.getLine() +
						      ": Type error for the logical expression.");
				TypeInfo att = TypeInfo.Error; $attr_type = att.ordinal();
        }
	  }
         
	;



if_then_statements: statement 
                  | '{' statements '}' 
				  ;

else_statements: statement 
                  | '{' statements '}' 
				  ;

for_statements: statement
              | '{' statements '}'
				  ;

while_statements: statement
                | '{' statements '}'
				  ;

print_fuction: PRINTF '(' STRING (',' Identifier)* ')'  ';' { if (TRACEON) System.out.println("PRINTF FUNCTION"); };

identifier_double: Identifier PP_OP ';' {if (TRACEON) System.out.println("plus plus statement");}
         | Identifier MM_OP ';' {if (TRACEON) System.out.println("minus minus statement");};




		   
/* ====== description of the tokens ====== */
FLOAT:'float';
INT:'int';
BOOL: 'bool';
MAIN: 'main';
VOID: 'void';
PRINTF: 'printf';
IF: 'if';
ELSE: 'else';
FOR: 'for';
WHILE: 'while';

EQ_OP : '==';
LE_OP : '<=';
GE_OP : '>=';
NE_OP : '!=';
LE_ : '<';
GR_ : '>'; 
PP_OP : '++';
MM_OP : '--';

Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:'0'..'9'+;
Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;
STRING : '\"'(.)*'\"';

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
COMMENT:'/*' .* '*/' {$channel=HIDDEN;};