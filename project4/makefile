all: generation compilation

generation:
	java -cp ../antlr-3.5.2-complete.jar org.antlr.Tool myCompiler.g

compilation:
	javac -cp ../antlr-3.5.2-complete.jar:. myCompilerLexer.java myCompilerParser.java myCompiler_test.java 

test1:
	java -cp ../antlr-3.5.2-complete.jar:. myCompiler_test test1.c > test1.ll
	lli test1.ll
test2:
	java -cp ../antlr-3.5.2-complete.jar:. myCompiler_test test2.c > test2.ll
	lli test2.ll
test3:
	java -cp ../antlr-3.5.2-complete.jar:. myCompiler_test test3.c > test3.ll
	lli test3.ll
clean:
	rm myCompilerLexer.java myCompilerParser.java
	rm myCompiler.tokens
	rm *.class
	rm test1.ll test2.ll test3.ll
