compile:
首先修改makefile 中antlr-3.5.2-complete.jar路徑，確保antlr-3.5.2-complete.jar 放在對的地方
執行make 
(編譯myparser.g testParser.java)

execution:
make test1 可測試test.c
make test2 可測試test2.c
make test3 可測試test3.c

make clean可清除.tokens .class等檔案