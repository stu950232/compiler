compile:
執行前必須先裝好antlr
首先修改makefile 中antlr-3.5.2-complete.jar路徑，確保antlr-3.5.2-complete.jar 放在對的地方
執行make 
(編譯myCompiler.g myCompilerLexer.java myCompilerParser.java myCompiler_test.java )

execution:
包含三個測試.c檔
test1.c,test2.c,test3.c

make test1 可從test1.c產生test1.ll 並對test1.ll進行直譯 (lli test1.ll)
make test2 可從test1.c產生test2.ll 並對test2.ll進行直譯 (lli test2.ll)
make test3 可從test3.c產生test3.ll 並對test3.ll進行直譯 (lli test3.ll)

make clean可清除Parser Lexer .tokens .class .ll等檔案

feature:
可將常數和變數混用做+-*/運算
可支援while 一層迴圈，while裡可以放if else
