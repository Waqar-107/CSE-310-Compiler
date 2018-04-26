%option noyywrap
%option c++

/* definition section */
%{

#include<stdio.h>
#include<stdlib.h>


FILE *logout;
FILE *tokenout;

int line=1;

%}


DIGIT [0-9]
DIGITS (DIGIT)+
LETTER [a-zA-Z]
NEWLINE "\n"
WHITESPACE [ \t\r\v\f]+
WORD [a-zA-Z]+
IDENTIFIER ([a-zA-Z]|"_")[a-zA-Z0-9_]*


/* a single line starts with 'double slash' and ends with a newline. 
*  in the middle, there can be literaly anything and any number of times.
*/
SINGLE_LINE_COMMENT "//"[^"\n"]*


/* for a multiline comment, it must start with backslash-star and 
*  ends with star-backslash 
*  in the middle there can be anything except star-backslash
*/
STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH "*"[^/]
ANYTHING_EXCEPT_STAR [^*]

MULTILINE_COMMENT ("/*")(ANYTHING_EXCEPT_STAR|STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH)*("*/")

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
INTEGER_LITERAL {DIGIT}+
FLOAT_LITERAL {DIGITS}(.{DIGITS})?(E[+-]?{DIGITS})?
/* ----------------------------------------------- */

/* rules section */
%%

{NEWLINE} {
	line++;
}

{SINGLE_LINE_COMMENT} {
	fprintf(logout,"Line no. %d: tokenout <SINGLE_LINE_COMMENT> Lexeme ' %s ' found\n",line,yytext);
}

{MULTILINE_COMMENT} {
	fprintf(logout,"Line no. %d: tokenout <MULTI_LINE_COMMENT> Lexeme ' %s ' found\n",line,yytext);
}

{BREAK} {
	fprintf(tokenout,"<BREAK>");
	fprintf(logout,"Line no. %d: tokenout <BREAK> Lexeme %s found\n",line,yytext);
}

{CASE} {
	fprintf(tokenout,"<CASE>");
	fprintf(logout,"Line no. %d: tokenout <CASE> Lexeme %s found\n",line,yytext);
}

{CHAR} {
	fprintf(tokenout,"<CHAR>");
	fprintf(logout,"Line no. %d: tokenout <CHAR> Lexeme %s found\n",line,yytext);
}

{CONTINUE} {
	fprintf(tokenout,"<CONTINUE>");
	fprintf(logout,"Line no. %d: tokenout <CONTINUE> Lexeme %s found\n",line,yytext);
}

{DEFAULT} {
	fprintf(tokenout,"<DEFAULT>");
	fprintf(logout,"Line no. %d: tokenout <DEFAULT> Lexeme %s found\n",line,yytext);
}

{DO} {
	fprintf(tokenout,"<DO>");
	fprintf(logout,"Line no. %d: tokenout <DO> Lexeme %s found\n",line,yytext);
}

{DOUBLE} {
	fprintf(tokenout,"<DOUBLE>");
	fprintf(logout,"Line no. %d: tokenout <DOUBLE> Lexeme %s found\n",line,yytext);
}

{ELSE} {
	fprintf(tokenout,"<ELSE>");
	fprintf(logout,"Line no. %d: tokenout <ELSE> Lexeme %s found\n",line,yytext);
}

{FLOAT} {
	fprintf(tokenout,"<FLOAT>");
	fprintf(logout,"Line no. %d: tokenout <FLOAT> Lexeme %s found\n",line,yytext);
}

{FOR} {
	fprintf(tokenout,"<FOR>");
	fprintf(logout,"Line no. %d: tokenout <FOR> Lexeme %s found\n",line,yytext);
}

{IF} {
	fprintf(tokenout,"<IF>");
	fprintf(logout,"Line no. %d: tokenout <IF> Lexeme %s found\n",line,yytext);
}

{INT} {
	fprintf(tokenout,"<INT>");
	fprintf(logout,"Line no. %d: tokenout <INT> Lexeme %s found\n",line,yytext);
}

{RETURN} {
	fprintf(tokenout,"<RETURN>");
	fprintf(logout,"Line no. %d: tokenout <RETURN> Lexeme %s found\n",line,yytext);
}

{SWITCH} {
	fprintf(tokenout,"<SWITCH>");
	fprintf(logout,"Line no. %d: tokenout <SWITCH> Lexeme %s found\n",line,yytext);
}

{WHILE} {
	fprintf(tokenout,"<WHILE>");
	fprintf(logout,"Line no. %d: tokenout <WHILE> Lexeme %s found\n",line,yytext);
}

{VOID} {
	fprintf(tokenout,"<VOID>");
	fprintf(logout,"Line no. %d: tokenout <VOID> Lexeme %s found\n",line,yytext);
}

{ADDOP} {
	fprintf(tokenout,"<ADDOP,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <ADDOP> Lexeme %s found\n",line,yytext);
}

{MULOP} {
	fprintf(tokenout,"<MULOP,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <MULOP> Lexeme %s found\n",line,yytext);
}

{RELOP} {
	fprintf(tokenout,"<RELOP,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <RELOP> Lexeme %s found\n",line,yytext);
}

{INCOP} {
	fprintf(tokenout,"<INCOP,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <INCOP> Lexeme %s found\n",line,yytext);
}

{LOGICOP} {
	fprintf(tokenout,"<LOGICOP,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <LOGICOP> Lexeme %s found\n",line,yytext);
}

{ASSIGNOP} {
	fprintf(tokenout,"<ASSIGNOP,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <ASSIGNOP> Lexeme %s found\n",line,yytext);
}

{NOT} {
	fprintf(tokenout,"<NOT,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <NOT> Lexeme %s found\n",line,yytext);
}

{LPAREN} {
	fprintf(tokenout,"<LPAREN,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <LPAREN> Lexeme %s found\n",line,yytext);
}

{RPAREN} {
	fprintf(tokenout,"<RPAREN,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <RPAREN> Lexeme %s found\n",line,yytext);
}

{LCURL} {
	fprintf(tokenout,"<LCURL,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <LCURL> Lexeme %s found\n",line,yytext);
}

{RCURL} {
	fprintf(tokenout,"<RCURL,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <RCURL> Lexeme %s found\n",line,yytext);
}

{LTHIRD} {
	fprintf(tokenout,"<LTHIRD,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <LTHIRD> Lexeme %s found\n",line,yytext);
}

{RTHIRD} {
	fprintf(tokenout,"<RTHIRD,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <RTHIRD> Lexeme %s found\n",line,yytext);
}

{COMMA} {
	fprintf(tokenout,"<COMMA,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <COMMA> Lexeme %s found\n",line,yytext);
}

{SEMICOLON} {
	fprintf(tokenout,"<SEMICOLON,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <SEMICOLON> Lexeme %s found\n",line,yytext);
}

{INTEGER_LITERAL} {
	fprintf(tokenout,"<CONST_INT,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <CONST_INT> Lexeme %s found\n",line,yytext);
}

{FLOAT_LITERAL} {
	fprintf(tokenout,"<CONST_FLOAT,%s>",yytext);
	fprintf(logout,"Line no. %d: tokenout <CONST_FLOAT> Lexeme %s found\n",line,yytext);
}

%%



int main(int argc,char **argv[])
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
	tokenout=fopen("tokenout.txt","w");
	

	yyin=in;
	yylex();

	fclose(yyin);
	fclose(logout);
	fclose(tokenout);

	return 0;
}
