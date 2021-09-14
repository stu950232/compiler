all:generate compile

generate:
	java -cp ../antlr-3.5.2-complete.jar org.antlr.Tool myparser.g
compile:
	javac -cp ../antlr-3.5.2-complete.jar:. testParser.java

test1:
	java -cp ../antlr-3.5.2-complete.jar:. testParser test.c
test2:
	java -cp ../antlr-3.5.2-complete.jar:. testParser test2.c
test3:
	java -cp ../antlr-3.5.2-complete.jar:. testParser test3.c
clean:
	rm myparserLexer.java myparserParser.java
	rm myparser.tokens
	rm *.class

