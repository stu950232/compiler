all: generation compilation

generation:
	java -cp ../antlr-3.5.2-complete.jar org.antlr.Tool myChecker.g

compilation:
	javac -cp ../antlr-3.5.2-complete.jar:. myChecker_test.java 

test1:
	java -cp ../antlr-3.5.2-complete.jar:. myChecker_test test.c

test2:
	java -cp ../antlr-3.5.2-complete.jar:. myChecker_test test2.c

test3:
	java -cp ../antlr-3.5.2-complete.jar:. myChecker_test test3.c

clean:
	rm myCheckerLexer.java myCheckerParser.java
	rm myChecker.tokens
	rm *.class
