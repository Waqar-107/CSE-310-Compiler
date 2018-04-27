%option noyywrap

/* definition section */
%{

#include<cstdio>
#include<cstdlib>
#include<string>
#include"1505107_SymbolTable.h"

using namespace std;

SymbolTable symbolTable(13);

FILE *logout;
FILE *tokenout;

int line=1;
int cnt_err=0;

void printScopeTableFlex(string s,string t){
	bool f=symbolTable.Insert(s,t,logout);
	if(f)
		symbolTable.PrintCurrentScopeTable(logout);

	fprintf(logout,"\n");
}

%}


DIGIT [0-9]
DIGITS {DIGIT}+
LETTER [a-zA-Z]
NEWLINE \n
WHITESPACE [ \t\r\v\f]+
WORD [a-zA-Z]+

/* a single line starts with 'double slash' and ends with a newline. 
*  in the middle, there can be literaly anything and any number of times.
*/
SINGLE_LINE_COMMENT "//"[^"\n"]*


/* for a multiline comment, it must start with backslash-star and 
*  ends with star-backslash 
*  in the middle there can be anything except star-backslash
*/
STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH "*"[^/]*
ANYTHING_EXCEPT_STAR [^*]*

MULTILINE_COMMENT ("/*")({ANYTHING_EXCEPT_STAR}|{STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH})("*/")

/* ----------------------------------------------- */
/* keywords */
BREAK "break"
CASE "case"
CHAR "char"
CONTINUE "continue"
DEFAULT "default"
DO "do"
DOUBLE "double"
ELSE "else"
FLOAT "float"
FOR "for"
IF "if"
INT "int"
RETURN "return"
SWITCH "switch"
WHILE "while"
VOID "void"
/* ----------------------------------------------- */

/* ----------------------------------------------- */
/* operators and punctuators */
ADDOP [+-]
MULOP [*/%]
INCOP ("++"|"--")
RELOP (">"|">="|"<"|"<="|"=="|"!=")
ASSIGNOP ("=")
LOGICOP ("&&"|"||")
NOT ("!")
LPAREN ("(")
RPAREN (")")
LCURL ("{")
RCURL ("}")
LTHIRD ("[")
RTHIRD ("]")
COMMA (",")
SEMICOLON (";")
/* ----------------------------------------------- */

/* ----------------------------------------------- */
/* Constants */
INTEGER_LITERAL {DIGITS}

/* the exponential part is optional
*  before that, there can be three variations
*  digits.digits, .digits, digits
*/

EXPONENTIAL E(+|-)?{DIGITS}
FLOAT_VAR_ONE {DIGITS}
FLOAT_LITERAL_v_TWO {DIGITS}(E(+|-)?{DIGITS})
FLOAT_LITERAL ({DIGITS}\.{DIGITS})
/* ----------------------------------------------- */

/* ----------------------------------------------- */
/* Identifiers */
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
/* ----------------------------------------------- */

/* rules section */
%%
{NEWLINE} {
	line++;
}

{SINGLE_LINE_COMMENT} {
	fprintf(logout,"Line no. %d: Token <SINGLE_LINE_COMMENT> Lexeme %s found\n\n",line,yytext);
}

{MULTILINE_COMMENT} {
	fprintf(logout,"Line no. %d: Token <MULTI_LINE_COMMENT> Lexeme %s found\n\n",line,yytext);
}

{BREAK} {
	fprintf(tokenout,"<BREAK>");
	fprintf(logout,"Line no. %d: Token <BREAK> Lexeme %s found\n\n",line,yytext);
}

{CASE} {
	fprintf(tokenout,"<CASE>");
	fprintf(logout,"Line no. %d: Token <CASE> Lexeme %s found\n\n",line,yytext);
}

{CHAR} {
	fprintf(tokenout,"<CHAR>");
	fprintf(logout,"Line no. %d: Token <CHAR> Lexeme %s found\n\n",line,yytext);
}

{CONTINUE} {
	fprintf(tokenout,"<CONTINUE>");
	fprintf(logout,"Line no. %d: Token <CONTINUE> Lexeme %s found\n\n",line,yytext);
}

{DEFAULT} {
	fprintf(tokenout,"<DEFAULT>");
	fprintf(logout,"Line no. %d: Token <DEFAULT> Lexeme %s found\n\n",line,yytext);
}

{DO} {
	fprintf(tokenout,"<DO>");
	fprintf(logout,"Line no. %d: Token <DO> Lexeme %s found\n\n",line,yytext);
}

{DOUBLE} {
	fprintf(tokenout,"<DOUBLE>");
	fprintf(logout,"Line no. %d: Token <DOUBLE> Lexeme %s found\n\n",line,yytext);
}

{ELSE} {
	fprintf(tokenout,"<ELSE>");
	fprintf(logout,"Line no. %d: Token <ELSE> Lexeme %s found\n\n",line,yytext);
}

{FLOAT} {
	fprintf(tokenout,"<FLOAT>");
	fprintf(logout,"Line no. %d: Token <FLOAT> Lexeme %s found\n\n",line,yytext);
}

{FOR} {
	fprintf(tokenout,"<FOR>");
	fprintf(logout,"Line no. %d: Token <FOR> Lexeme %s found\n\n",line,yytext);
}

{IF} {
	fprintf(tokenout,"<IF>");
	fprintf(logout,"Line no. %d: Token <IF> Lexeme %s found\n\n",line,yytext);
}

{INT} {
	fprintf(tokenout,"<INT>");
	fprintf(logout,"Line no. %d: Token <INT> Lexeme %s found\n\n",line,yytext);

}

{RETURN} {
	fprintf(tokenout,"<RETURN>");
	fprintf(logout,"Line no. %d: Token <RETURN> Lexeme %s found\n\n",line,yytext);
}

{SWITCH} {
	fprintf(tokenout,"<SWITCH>");
	fprintf(logout,"Line no. %d: Token <SWITCH> Lexeme %s found\n\n",line,yytext);
}

{WHILE} {
	fprintf(tokenout,"<WHILE>");
	fprintf(logout,"Line no. %d: Token <WHILE> Lexeme %s found\n\n",line,yytext);
}

{VOID} {
	fprintf(tokenout,"<VOID>");
	fprintf(logout,"Line no. %d: Token <VOID> Lexeme %s found\n\n",line,yytext);
}

{ADDOP} {
	fprintf(tokenout,"<ADDOP,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <ADDOP> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"ADDOP");
}

{MULOP} {
	fprintf(tokenout,"<MULOP,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <MULOP> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"MULOP");
}

{RELOP} {
	fprintf(tokenout,"<RELOP,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <RELOP> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"RELOP");
}

{INCOP} {
	fprintf(tokenout,"<INCOP,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <INCOP> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"INCOP");
}

{LOGICOP} {
	fprintf(tokenout,"<LOGICOP,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <LOGICOP> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"LOGICOP");
}

{ASSIGNOP} {
	fprintf(tokenout,"<ASSIGNOP,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <ASSIGNOP> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"ASSIGNOP");
}

{NOT} {
	fprintf(tokenout,"<NOT,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <NOT> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"NOT");
}

{LPAREN} {
	fprintf(tokenout,"<LPAREN,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <LPAREN> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"LPAREN");
}

{RPAREN} {
	fprintf(tokenout,"<RPAREN,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <RPAREN> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"RPAREN");
}

{LCURL} {
	fprintf(tokenout,"<LCURL,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <LCURL> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"LCURL");
}

{RCURL} {
	fprintf(tokenout,"<RCURL,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <RCURL> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"RCURL");
}

{LTHIRD} {
	fprintf(tokenout,"<LTHIRD,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <LTHIRD> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"LTHIRD");
}

{RTHIRD} {
	fprintf(tokenout,"<RTHIRD,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <RTHIRD> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"RTHIRD");
}

{COMMA} {
	fprintf(tokenout,"<COMMA,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <COMMA> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"COMMA");
}

{SEMICOLON} {
	fprintf(tokenout,"<SEMICOLON,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <SEMICOLON> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"SEMICOLON");
}

{INTEGER_LITERAL} {
	fprintf(tokenout,"<CONST_INT,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <CONST_INT> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"CONST_INT");
}

{FLOAT_LITERAL} {
	fprintf(tokenout,"<CONST_FLOAT,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <CONST_FLOAT> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"CONST_FLOAT");
}

{IDENTIFIER} {
	fprintf(tokenout,"<ID,%s>",yytext);
	fprintf(logout,"Line no. %d: Token <ID> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"ID");
}


%%



int main(int argc,char *argv[])
{
	if(argc!=2){
		printf("provide with the input file name and try again!!!\n");
		return 0;
	}

	FILE *in=fopen(argv[1],"r");
	if(in==NULL){
		printf("Something Went Wrong :(, Couldn't Open The Specified File\n");
	}

	
	logout=fopen("log.txt","w");
	tokenout=fopen("token.txt","w");
	

	yyin=in;
	yylex();

	fclose(yyin);
	fclose(logout);
	fclose(tokenout);

	return 0;
}
