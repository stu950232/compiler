grammar myCompiler;

options {
   language = Java;
}

@header {
    // import packages here.
    import java.util.HashMap;
    import java.util.ArrayList;
}

@members {
    boolean TRACEON = false;

    // Type information.
    public enum Type{
       ERR, BOOL, INT, FLOAT, CHAR, CONST_INT, CONST_FLOAT, DOUBLE;
    }

    // This structure is used to record the information of a variable or a constant.
    class tVar {
	   int   varIndex; // temporary variable's index. Ex: t1, t2, ..., etc.
	   int   iValue;   // value of constant integer. Ex: 123.
	   float fValue;   // value of constant floating point. Ex: 2.314.
	};

    class Info {
       Type theType;  // type information.
       tVar theVar;
	   
	   Info() {
        theType = Type.ERR;
		  theVar = new tVar();
	   }
    };

	
    // ============================================
    // Create a symbol table.
	// ArrayList is easy to extend to add more info. into symbol table.
	//
	// The structure of symbol table:
	// <variable ID, [Type, [varIndex or iValue, or fValue]]>
	//    - type: the variable type   (please check "enum Type")
	//    - varIndex: the variable's index, ex: t1, t2, ...
	//    - iValue: value of integer constant.
	//    - fValue: value of floating-point constant.
    // ============================================

    HashMap<String, Info> symtab = new HashMap<String, Info>();

    // labelCount is used to represent temporary label.
    // The first index is 0.
    int labelCount = 0;
	
    // varCount is used to represent temporary variables.
    // The first index is 0.
    int varCount = 0;

    // Record all assembly instructions.
    List<String> TextCode = new ArrayList<String>();

    int if_stmt_else;

    int if_stmt_end;
    int while_be,while_lo,while_end;
    /*
     * Output prologue.
     */
    void prologue()
    {
      TextCode.add("; === prologue ====");
      TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
      TextCode.add("@.str = private unnamed_addr constant [4 x i8] c\"\%d\\0A\\00\", align 1\n");
      TextCode.add("@.str_f = private unnamed_addr constant [4 x i8] c\"\%f\\0A\\00\", align 1\n");
	   TextCode.add("define dso_local i32 @main()");
	   TextCode.add("{");
    }
    
	
    /*
     * Output epilogue.
     */
    void epilogue()
    {
      /* handle epilogue */
      TextCode.add("\n; === epilogue ===");
	   TextCode.add("ret i32 0");
      TextCode.add("}");
    }
    
    
    /* Generate a new label */
    String newLabel()
    {
       labelCount ++;
       return (new String("L")) + Integer.toString(labelCount);
    } 
    
    
    public List<String> getTextCode()
    {
       return TextCode;
    }
}

program: VOID MAIN '(' ')'
        {
           /* Output function prologue */
           prologue();
        }

        '{' 
           declarations
           statements
        '}'
        {
	   if (TRACEON)
	      System.out.println("VOID MAIN () {declarations statements}");

           /* output function epilogue */	  
           epilogue();
        }
        ;


declarations: type Identifier ';' declarations
        {
           if (TRACEON)
              System.out.println("declarations: type Identifier : declarations");

           if (symtab.containsKey($Identifier.text)) {
              // variable re-declared.
              System.out.println("Type Error: " + 
                                  $Identifier.getLine() + 
                                 ": Redeclared identifier.");
              System.exit(0);
           }
                 
           /* Add ID and its info into the symbol table. */
            Info the_entry = new Info();
            the_entry.theType = $type.attr_type;
            the_entry.theVar.varIndex = varCount;
            varCount ++;
            symtab.put($Identifier.text, the_entry);

           // issue the instruction.
		     // Ex: \%a = alloca i32, align 4
           if ($type.attr_type == Type.INT) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
           }
           // Ex: \%a = alloca float, align 4
           if ($type.attr_type == Type.FLOAT) { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
           }
        }
        | 
        {
           if (TRACEON)
              System.out.println("declarations: ");
        }
        ;


type
returns [Type attr_type]
    : INT { if (TRACEON) System.out.println("type: INT"); $attr_type=Type.INT; }
    | CHAR { if (TRACEON) System.out.println("type: CHAR"); $attr_type=Type.CHAR; }
    | FLOAT {if (TRACEON) System.out.println("type: FLOAT"); $attr_type=Type.FLOAT; }
    | DOUBLE {if (TRACEON) System.out.println("type: DOUBLE"); $attr_type=Type.DOUBLE; }
	;


statements:statement statements
          |
          ;


statement: assign_stmt ';'
         | if_stmt
         | func_no_return_stmt ';'
         | for_stmt
         | print_fuction ';'
         | while_stmt 
         ;

for_stmt: FOR '(' assign_stmt ';'
                  cond_expression ';'
                  assign_stmt
              ')'
                  block_stmt
        ;

while_stmt: {
               TextCode.add("br label \%t" + varCount);
               while_be=varCount;
               varCount++;
               TextCode.add("t"+while_be+":");
            }	
            WHILE '(' a = cond_expression ')'
            {  if($a.theInfo.theType == Type.BOOL){
                  int while_jud = varCount;
                  TextCode.add("br i1 \%t" + $a.theInfo.theVar.varIndex + ", label \%t" + varCount++ + ", label \%t" + varCount + "\n");
                  TextCode.add("t"+ while_jud + ":");
                  while_end = varCount;
                  varCount++;
               }
            } block_stmt
            {
               TextCode.add("br label \%t" + while_be + "\n");
               TextCode.add("t"+ while_end + ":");
            }
;
		 
if_stmt
            : if_then_stmt if_else_stmt
            ;

	   
if_then_stmt
returns [Info theInfo]
@init {theInfo = new Info();}
            : IF '(' a = cond_expression { $theInfo=$a.theInfo; } ')' 
             {
                if($a.theInfo.theType == Type.BOOL){
                   int if_stmt_then = varCount;
                   TextCode.add("br i1 \%t" + theInfo.theVar.varIndex + ", label \%t" + varCount++ + ", label \%t" + varCount + "\n");
                   TextCode.add("t"+ if_stmt_then + ":");
                   if_stmt_else = varCount;
                   varCount++;
                }
             }block_stmt
             {
                TextCode.add("br label \%t" + varCount + "\n");
                if_stmt_end = varCount;
                varCount++;
             }
            ;


if_else_stmt
            : ELSE
            {
                TextCode.add("t"+ if_stmt_else + ":");
            }
            block_stmt
            {
               TextCode.add("br label \%t" + if_stmt_end + "\n");
               TextCode.add("t"+ if_stmt_end + ":");
            }
            ;

				  
block_stmt: '{' statements '}'
	  ;


assign_stmt: Identifier '=' arith_expression
             {
                Info theRHS = $arith_expression.theInfo;
				    Info theLHS = symtab.get($Identifier.text); 
		   
                if ((theLHS.theType == Type.INT) &&
                    (theRHS.theType == Type.INT)) {		   
                   // issue store insruction.
                   // Ex: store i32 \%tx, i32* \%ty
                   TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex);
				   } else if ((theLHS.theType == Type.INT) &&
				    (theRHS.theType == Type.CONST_INT)) {
                   // issue store insruction.
                   // Ex: store i32 value, i32* \%ty
                   TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex);
                   theLHS.theVar.iValue=theRHS.theVar.iValue;
				   } else if ((theLHS.theType == Type.FLOAT) &&
                    (theRHS.theType == Type.FLOAT)) {		   
                   // issue store insruction.
                   // Ex: store float \%tx, float* \%ty
                   TextCode.add("store float \%t" + theRHS.theVar.varIndex + ", float* \%t" + theLHS.theVar.varIndex);
				   } else if ((theLHS.theType == Type.FLOAT) &&
				    (theRHS.theType == Type.CONST_FLOAT)) {
                   // issue store insruction.
                   // Ex: store float value, float* \%ty
                   //double num=Float.doubleValue(theRHS.theVar.fValue);
                   long ans2 = Double.doubleToLongBits(theRHS.theVar.fValue);
                   TextCode.add("store float 0x" + Long.toHexString(ans2) + ", float* \%t" + theLHS.theVar.varIndex);
                   theLHS.theVar.fValue=theRHS.theVar.fValue;				
				   } else if ((theLHS.theType == Type.FLOAT) &&
                  (theRHS.theType == Type.DOUBLE)) {		   
                   // issue store insruction.
                   // Ex: store i32 \%tx, i32* \%ty
                   TextCode.add("\%t" + varCount + " = fptrunc double \%t" + theRHS.theVar.varIndex + " to float");
                   theRHS.theType = Type.FLOAT;
                   theRHS.theVar.varIndex = varCount;
                   varCount ++;	
                   TextCode.add("store float \%t" + theRHS.theVar.varIndex + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");		
		         }
			 }
;

		   
func_no_return_stmt: Identifier '(' argument ')'
                   ;


argument: arg (',' arg)*
        ;

arg: arith_expression
   | STRING_LITERAL
   ;
		   
cond_expression
returns [Info theInfo]
@init {theInfo = new Info();}
                : a=arith_expression { $theInfo=$a.theInfo; }
                 ( '>' b=arith_expression
                    {  if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					           ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $a.theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					           ($b.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp ogt float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					           ($b.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					           ($b.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp ogt double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					           ($b.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp ogt double " + $a.theInfo.theVar.fValue + ", " + $b.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                     }
                  | '<' c=arith_expression
                    {  if (($a.theInfo.theType == Type.INT) &&
                           ($c.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					           ($c.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($c.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp slt i32 " + $a.theInfo.theVar.iValue + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($c.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp slt i32 " + $a.theInfo.theVar.iValue + ", " + $c.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					          ($c.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp olt float \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					          ($c.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					          ($c.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $c.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp olt double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					          ($c.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp olt double " + $a.theInfo.theVar.fValue + ", " + $c.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                     }
                  | '>=' d=arith_expression
                    {  if (($a.theInfo.theType == Type.INT) &&
                           ($d.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $d.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					           ($d.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $theInfo.theVar.varIndex + ", " + $d.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($d.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sge i32 " + $a.theInfo.theVar.iValue + ", \%t" + $d.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($d.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sge i32 " + $a.theInfo.theVar.iValue + ", " + $d.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					          ($d.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp oge float \%t" + $theInfo.theVar.varIndex + ", \%t" + $d.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					          ($d.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + $theInfo.theVar.varIndex + ", " + $d.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					          ($d.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $d.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp oge double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					          ($d.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp oge double " + $a.theInfo.theVar.fValue + ", " + $d.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                     }
                  | '<=' e=arith_expression
                    {  if (($a.theInfo.theType == Type.INT) &&
                           ($e.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $e.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					           ($e.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $theInfo.theVar.varIndex + ", " + $e.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($e.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sle i32 " + $a.theInfo.theVar.iValue + ", \%t" + $e.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($e.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp sle i32 " + $a.theInfo.theVar.iValue + ", " + $e.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					           ($e.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp ole float \%t" + $theInfo.theVar.varIndex + ", \%t" + $e.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					           ($e.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + $theInfo.theVar.varIndex + ", " + $e.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					           ($e.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $e.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp ole double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					           ($e.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp ole double " + $a.theInfo.theVar.fValue + ", " + $e.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                     }
                  | '==' f=arith_expression
                    {  if (($a.theInfo.theType == Type.INT) &&
                           ($f.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $f.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					           ($f.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $theInfo.theVar.varIndex + ", " + $f.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($f.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp eq i32 " + $a.theInfo.theVar.iValue + ", \%t" + $f.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($f.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp eq i32 " + $a.theInfo.theVar.iValue + ", " + $f.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					         ($f.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp oeq float \%t" + $theInfo.theVar.varIndex + ", \%t" + $f.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					          ($f.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++; 
                           TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + $theInfo.theVar.varIndex + ", " + $f.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					          ($f.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $f.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++; 
                           TextCode.add("\%t" + varCount + " = fcmp oeq double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					          ($f.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp oeq double " + $a.theInfo.theVar.fValue + ", " + $f.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                     }
                  | '!=' g=arith_expression
                    {  if (($a.theInfo.theType == Type.INT) &&
                           ($g.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $g.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					           ($g.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $theInfo.theVar.varIndex + ", " + $g.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($g.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = icmp ne i32 " + $a.theInfo.theVar.iValue + ", \%t" + $g.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($g.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = icmp ne i32 " + $a.theInfo.theVar.iValue + ", " + $g.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					         ($g.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp one float \%t" + $theInfo.theVar.varIndex + ", \%t" + $g.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					           ($g.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp one double \%t" + $theInfo.theVar.varIndex + ", " + $g.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					           ($g.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float \%t" + $g.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fcmp one double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					           ($g.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fcmp one double " + $a.theInfo.theVar.fValue + ", " + $g.theInfo.theVar.fValue);
                           $theInfo.theType = Type.BOOL;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                     }
                 )*
               ;
			   
arith_expression
returns [Info theInfo]
@init {theInfo = new Info();}
                : a=multExpr { $theInfo=$a.theInfo; }
                 ( '+' b=multExpr
                    {
                       // We need to do type checking first.
                       // ...
					  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					           ($b.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($b.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = add nsw i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($b.theInfo.theType == Type.CONST_INT)) {
                           $theInfo.theVar.iValue = $a.theInfo.theVar.iValue + $b.theInfo.theVar.iValue;
                           // TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + num);
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.CONST_INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
                          ($b.theInfo.theType == Type.FLOAT)) {
						         TextCode.add("\%t" + varCount + " = fadd float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.FLOAT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					         ($b.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.fValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           //System.out.println($theInfo.theType);
                           varCount ++;
                           $theInfo.theVar.fValue=$a.theInfo.theVar.fValue+$b.theInfo.theVar.fValue;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					         ($b.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $b.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fadd double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           //System.out.println($theInfo.theType);
                           varCount ++;
                           $theInfo.theVar.fValue=$a.theInfo.theVar.fValue+$b.theInfo.theVar.fValue;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					           ($b.theInfo.theType == Type.CONST_FLOAT)) {
                           // TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                           // $theInfo.theVar.varIndex = varCount;
                           // varCount ++;
                           // TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.fValue);
			  				      $theInfo.theVar.fValue = $a.theInfo.theVar.fValue + $b.theInfo.theVar.fValue;
		   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.CONST_FLOAT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.DOUBLE) &&
                           ($b.theInfo.theType == Type.DOUBLE)) {
                           TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.DOUBLE) &&
					            ($b.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.fValue);
                        
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					         ($b.theInfo.theType == Type.DOUBLE)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					         ($b.theInfo.theType == Type.DOUBLE)) {
                           TextCode.add("\%t" + varCount + " = fadd double " + $a.theInfo.theVar.fValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.DOUBLE) &&
					         ($b.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $b.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fadd double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                    }
                 | '-' c=multExpr
                    {
                       // We need to do type checking first.
                       // ...
					  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($c.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.INT) &&
					         ($c.theInfo.theType == Type.CONST_INT)) {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					         ($c.theInfo.theType == Type.INT)) {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 " + $a.theInfo.theVar.iValue + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_INT) &&
					           ($c.theInfo.theType == Type.CONST_INT)) {
			  				      $theInfo.theVar.iValue = $a.theInfo.theVar.iValue - $c.theInfo.theVar.iValue;
                           // TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + num);
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.CONST_INT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
                           ($c.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fsub float \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.FLOAT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					         ($c.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.fValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                      } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					         ($c.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $c.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fsub double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                      } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					         ($c.theInfo.theType == Type.CONST_FLOAT)) {
                           // TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                           // $theInfo.theVar.varIndex = varCount;
                           // varCount ++;
                           // TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.fValue);
			                  $theInfo.theVar.fValue = $a.theInfo.theVar.fValue - $c.theInfo.theVar.fValue;
		   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.CONST_FLOAT;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                      } else if (($a.theInfo.theType == Type.DOUBLE) &&
                        ($c.theInfo.theType == Type.DOUBLE)) {
                           TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.DOUBLE) &&
					          ($c.theInfo.theType == Type.CONST_FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.fValue);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.FLOAT) &&
					          ($c.theInfo.theType == Type.DOUBLE)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					          ($c.theInfo.theType == Type.DOUBLE)) {
                           TextCode.add("\%t" + varCount + " = fsub double " + $a.theInfo.theVar.fValue + ", \%t" + $c.theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       } else if (($a.theInfo.theType == Type.DOUBLE) &&
					          ($c.theInfo.theType == Type.FLOAT)) {
                           TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $c.theInfo.theVar.varIndex + " to double");
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                           TextCode.add("\%t" + varCount + " = fsub double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $theInfo.theVar.varIndex);
					   
                           // Update arith_expression's theInfo.
                           $theInfo.theType = Type.DOUBLE;
                           $theInfo.theVar.varIndex = varCount;
                           varCount ++;
                       }
                     }
                 )*
                 ;

multExpr
returns [Info theInfo]
@init {theInfo = new Info();}
          : a=signExpr { $theInfo=$a.theInfo; }
          ( '*' b = signExpr
            {
               // We need to do type checking first.
               // ...
         
               // code generation.					   
               if (($a.theInfo.theType == Type.INT) &&
                  ($b.theInfo.theType == Type.INT)) {
                  TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.INT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.INT) &&
                  ($b.theInfo.theType == Type.CONST_INT)) {
                  TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.INT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_INT) &&
                  ($b.theInfo.theType == Type.INT)) {
                  TextCode.add("\%t" + varCount + " = mul nsw i32 " + $a.theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.INT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_INT) &&
                  ($b.theInfo.theType == Type.CONST_INT)) {
                  $theInfo.theVar.iValue = $a.theInfo.theVar.iValue * $b.theInfo.theVar.iValue;
                  // TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + num);
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CONST_INT;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.FLOAT) &&
                  ($b.theInfo.theType == Type.FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fmul float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.FLOAT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.FLOAT) &&
                  ($b.theInfo.theType == Type.CONST_FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.fValue);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
                  ($b.theInfo.theType == Type.FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $b.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fmul double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					   ($b.theInfo.theType == Type.CONST_FLOAT)) {
                  // TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                  // $theInfo.theVar.varIndex = varCount;
                  // varCount ++;
                  // TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.fValue);
			         $theInfo.theVar.fValue = $a.theInfo.theVar.fValue * $b.theInfo.theVar.fValue;
		   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CONST_FLOAT;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.DOUBLE) &&
                  ($b.theInfo.theType == Type.DOUBLE)) {
                  TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
            
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.DOUBLE;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.DOUBLE) &&
                  ($b.theInfo.theType == Type.CONST_FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.fValue);
            
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.DOUBLE;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.FLOAT) &&
                  ($b.theInfo.theType == Type.DOUBLE)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
                  ($b.theInfo.theType == Type.DOUBLE)) {
                  TextCode.add("\%t" + varCount + " = fmul double " + $a.theInfo.theVar.fValue + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.DOUBLE) &&
                  ($b.theInfo.theType == Type.FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $b.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fmul double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else{System.out.println($b.theInfo.theType);}
            }
          | '/' c=signExpr
            {
               // We need to do type checking first.
               // ...
         
               // code generation.					   
               if (($a.theInfo.theType == Type.INT) &&
                  ($c.theInfo.theType == Type.INT)) {
                  TextCode.add("\%t" + varCount + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.INT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.INT) &&
               ($c.theInfo.theType == Type.CONST_INT)) {
                  TextCode.add("\%t" + varCount + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.INT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_INT) &&
                 ($c.theInfo.theType == Type.INT)) {
                  TextCode.add("\%t" + varCount + " = sdiv i32 " + $a.theInfo.theVar.iValue + ", \%t" + $c.theInfo.theVar.varIndex);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.INT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_INT) &&
               ($c.theInfo.theType == Type.CONST_INT)) {
                  $theInfo.theVar.iValue = $a.theInfo.theVar.iValue / $c.theInfo.theVar.iValue;
                  // TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + num);
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CONST_INT;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.FLOAT) &&
                  ($c.theInfo.theType == Type.FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fdiv float \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
         
                  // Update arith_expression's theInfo.
                  $theInfo.theType = Type.FLOAT;
                  $theInfo.theVar.varIndex = varCount;
                  varCount ++;
               } else if (($a.theInfo.theType == Type.FLOAT) &&
                  ($c.theInfo.theType == Type.CONST_FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.fValue);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
                  ($c.theInfo.theType == Type.FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $c.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fdiv double " + $a.theInfo.theVar.fValue + ", \%t" + $theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
					   ($c.theInfo.theType == Type.CONST_FLOAT)) {
                  // TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
                  // $theInfo.theVar.varIndex = varCount;
                  // varCount ++;
                  // TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.fValue);
			         $theInfo.theVar.fValue = $a.theInfo.theVar.fValue / $c.theInfo.theVar.fValue;
		   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CONST_FLOAT;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.DOUBLE) &&
                  ($c.theInfo.theType == Type.DOUBLE)) {
                  TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.DOUBLE) &&
					   ($c.theInfo.theType == Type.CONST_FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.fValue);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.FLOAT) &&
                 ($c.theInfo.theType == Type.DOUBLE)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $a.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.CONST_FLOAT) &&
                 ($c.theInfo.theType == Type.DOUBLE)) {
                  TextCode.add("\%t" + varCount + " = fdiv double " + $a.theInfo.theVar.fValue + ", \%t" + $c.theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               } else if (($a.theInfo.theType == Type.DOUBLE) &&
                 ($c.theInfo.theType == Type.FLOAT)) {
                  TextCode.add("\%t" + varCount + " = fpext float " + "\%t" + $c.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
                  TextCode.add("\%t" + varCount + " = fdiv double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $theInfo.theVar.varIndex);
					   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
               }
            }
	  )*
	  ;

signExpr
returns [Info theInfo]
@init {theInfo = new Info();}
        : a=primaryExpr { $theInfo=$a.theInfo; } 
        | '-' primaryExpr
	;
		  
primaryExpr
returns [Info theInfo]
@init {theInfo = new Info();}
           : Integer_constant
	        {
                $theInfo.theType = Type.CONST_INT;
			       $theInfo.theVar.iValue = Integer.parseInt($Integer_constant.text);
               //  $theInfo.theVar.varIndex = varCount;
					//  varCount ++;
           }
           | Floating_point_constant
           {
                $theInfo.theType = Type.CONST_FLOAT;
                $theInfo.theVar.fValue = Float.parseFloat($Floating_point_constant.text);
               //  $theInfo.theVar.varIndex = varCount;
					//  varCount ++;
           }
           | Identifier
           {
                // get type information from symtab.
                Type the_type = symtab.get($Identifier.text).theType;
				    $theInfo.theType = the_type;

                // get variable index from symtab.
                int vIndex = symtab.get($Identifier.text).theVar.varIndex;
				
                switch (the_type) {
                case INT: 
                   // get a new temporary variable and
						 // load the variable into the temporary variable.
                         
						 // Ex: \%tx = load i32, i32* \%ty.
						 TextCode.add("\%t" + varCount + "=load i32, i32* \%t" + vIndex);
				         
						 // Now, Identifier's value is at the temporary variable \%t[varCount].
						 // Therefore, update it.
						 $theInfo.theVar.varIndex = varCount;
						 varCount ++;
                         break;
                case FLOAT:
                   // get a new temporary variable and
						 // load the variable into the temporary variable.
                         
						 // Ex: \%tx = load float, float* \%ty.
						 TextCode.add("\%t" + varCount + "=load float, float* \%t" + vIndex);
				         
						 // Now, Identifier's value is at the temporary variable \%t[varCount].
						 // Therefore, update it.
						 $theInfo.theVar.varIndex = varCount;
						 varCount ++;
                         break;
                case CHAR:
                         break;
			
                }
           }
	         | '&' Identifier
	         | '(' a=arith_expression ')'
           {
               if($a.theInfo.theType == Type.INT) {
                  $theInfo.theType = Type.INT;
                  $theInfo.theVar.varIndex = varCount-1;
                  //varCount ++;
               } else if ($a.theInfo.theType == Type.FLOAT) {
                  $theInfo.theType=Type.FLOAT;
                  $theInfo.theVar.varIndex = varCount-1;
                  //varCount ++;
               } else if($a.theInfo.theType == Type.CONST_INT) {
                  $theInfo.theType = Type.CONST_INT;
                  $theInfo.theVar.varIndex = varCount-1;
                  $theInfo.theVar.iValue = $a.theInfo.theVar.iValue;
                  //varCount ++;
               } else if($a.theInfo.theType == Type.DOUBLE){ 
                  $theInfo.theType = Type.DOUBLE; 
                  $theInfo.theVar.varIndex = varCount-1;
                  $theInfo.theVar.fValue = $a.theInfo.theVar.fValue;
               }
           }
      ;

//  print_fuction: PRINTF '(' STRING_LITERAL ',' 
//          Identifier
//          {
//             Type the_type = symtab.get($Identifier.text).theType;
//             int vIndex = symtab.get($Identifier.text).theVar.varIndex;
//             switch (the_type) {
//                   case INT:
//                      TextCode.add("\%t" + varCount + "=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), i32 \%t" + vIndex + ")");
//                      varCount++;
//                      break;
//             }
//          }
//       // |Integer_constant
//       // |Floating_point_constant

//  ')' 
// ;

print_fuction: PRINTF '(' STRING_LITERAL  ',' a=primaryExpr
      {
         if ($a.theInfo.theType == Type.INT)
         {
            TextCode.add("\%t" + varCount + "=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ")");
            varCount++;
         }
         else if ($a.theInfo.theType == Type.CONST_INT)
         {
            TextCode.add("\%t" + varCount + "=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), i32 " + $a.theInfo.theVar.iValue + ")");
            varCount++;
         }
         else if ($a.theInfo.theType == Type.FLOAT)
         {
            TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
            $a.theInfo.theVar.varIndex=varCount;
            varCount++;
            TextCode.add("\%t" + varCount + "=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str_f, i32 0, i32 0), double \%t" + $a.theInfo.theVar.varIndex + ")");
            varCount++;
         }
         else if ($a.theInfo.theType == Type.CONST_FLOAT)
         {
            TextCode.add("\%t" + varCount + "=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str_f, i32 0, i32 0), double " + $a.theInfo.theVar.fValue + ")");
            varCount++;
         }
         else if ($a.theInfo.theType == Type.DOUBLE)
         {
            TextCode.add("\%t" + varCount + "=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str_f, i32 0, i32 0), double \%t" + $a.theInfo.theVar.varIndex + ")");
            varCount++;
         }
      }
 ')' 
;

		   
/* description of the tokens */
FLOAT:'float';
INT:'int';
CHAR: 'char';
DOUBLE: 'double';

MAIN: 'main';
VOID: 'void';
IF: 'if';
ELSE: 'else';
FOR: 'for';
PRINTF: 'printf';
WHILE:'while';
//RelationOP: '>' |'>=' | '<' | '<=' | '==' | '!=';

Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:'0'..'9'+;
Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;

STRING_LITERAL
    :  '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
COMMENT:'/*' .* '*/' {$channel=HIDDEN;};


fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    ;
