# CSE-310-Compiler

<h3>How to compile .l files:<br>assuming name of the file is "scanner.l"<br></h3>

```
lex scanner.l
gcc lex.yy.c -lfl
./a.out

```

<h3>1. Implementation of three classes: SymbolInfo, ScopeTable and SymbolTable</h3>
