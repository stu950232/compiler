all:generate compile

generate:
	java -cp ../antlr-3.5.2-complete.jar org.antlr.Tool mylexer.g
compile:
	javac -cp ../antlr-3.5.2-complete.jar testLexer.java mylexer.java

test1:
	java -cp ../antlr-3.5.2-complete.jar:. testLexer test1.c
test2:
	java -cp ../antlr-3.5.2-complete.jar:. testLexer test2.c
test3:
	java -cp ../antlr-3.5.2-complete.jar:. testLexer test3.c
clean:
	rm mylexer.java mylexer.tokens mylexer.class testLexer.class
