%option noyywrap
%option c++

/* definition section */
%{

#include<stdio.h>
#include<stdlib.h>


FILE *f_log;
FILE *token;

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
	fprintf(f_log,"Line no. %d: TOKEN <SINGLE_LINE_COMMENT> Lexeme ' %s ' found\n",line,yytext);
}

{MULTILINE_COMMENT} {
	fprintf(f_log,"Line no. %d: TOKEN <MULTI_LINE_COMMENT> Lexeme ' %s ' found\n",line,yytext);
}

{BREAK} {
	fprintf(token,"<BREAK>");
	fprintf(f_log,"Line no. %d: TOKEN <BREAK> Lexeme %s found\n",line,yytext);
}

{CASE} {
	fprintf(token,"<CASE>");
	fprintf(f_log,"Line no. %d: TOKEN <CASE> Lexeme %s found\n",line,yytext);
}

{CHAR} {
	fprintf(token,"<CHAR>");
	fprintf(f_log,"Line no. %d: TOKEN <CHAR> Lexeme %s found\n",line,yytext);
}

{CONTINUE} {
	fprintf(token,"<CONTINUE>");
	fprintf(f_log,"Line no. %d: TOKEN <CONTINUE> Lexeme %s found\n",line,yytext);
}

{DEFAULT} {
	fprintf(token,"<DEFAULT>");
	fprintf(f_log,"Line no. %d: TOKEN <DEFAULT> Lexeme %s found\n",line,yytext);
}

{DO} {
	fprintf(token,"<DO>");
	fprintf(f_log,"Line no. %d: TOKEN <DO> Lexeme %s found\n",line,yytext);
}

{DOUBLE} {
	fprintf(token,"<DOUBLE>");
	fprintf(f_log,"Line no. %d: TOKEN <DOUBLE> Lexeme %s found\n",line,yytext);
}

{ELSE} {
	fprintf(token,"<ELSE>");
	fprintf(f_log,"Line no. %d: TOKEN <ELSE> Lexeme %s found\n",line,yytext);
}

{FLOAT} {
	fprintf(token,"<FLOAT>");
	fprintf(f_log,"Line no. %d: TOKEN <FLOAT> Lexeme %s found\n",line,yytext);
}

{FOR} {
	fprintf(token,"<FOR>");
	fprintf(f_log,"Line no. %d: TOKEN <FOR> Lexeme %s found\n",line,yytext);
}

{IF} {
	fprintf(token,"<IF>");
	fprintf(f_log,"Line no. %d: TOKEN <IF> Lexeme %s found\n",line,yytext);
}

{INT} {
	fprintf(token,"<INT>");
	fprintf(f_log,"Line no. %d: TOKEN <INT> Lexeme %s found\n",line,yytext);
}

{RETURN} {
	fprintf(token,"<RETURN>");
	fprintf(f_log,"Line no. %d: TOKEN <RETURN> Lexeme %s found\n",line,yytext);
}

{SWITCH} {
	fprintf(token,"<SWITCH>");
	fprintf(f_log,"Line no. %d: TOKEN <SWITCH> Lexeme %s found\n",line,yytext);
}

{WHILE} {
	fprintf(token,"<WHILE>");
	fprintf(f_log,"Line no. %d: TOKEN <WHILE> Lexeme %s found\n",line,yytext);
}

{VOID} {
	fprintf(token,"<VOID>");
	fprintf(f_log,"Line no. %d: TOKEN <VOID> Lexeme %s found\n",line,yytext);
}

{ADDOP} {
	fprintf(token,"<ADDOP,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <ADDOP> Lexeme %s found\n",line,yytext);
}

{MULOP} {
	fprintf(token,"<MULOP,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <MULOP> Lexeme %s found\n",line,yytext);
}

{RELOP} {
	fprintf(token,"<RELOP,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <RELOP> Lexeme %s found\n",line,yytext);
}

{INCOP} {
	fprintf(token,"<INCOP,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <INCOP> Lexeme %s found\n",line,yytext);
}

{LOGICOP} {
	fprintf(token,"<LOGICOP,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <LOGICOP> Lexeme %s found\n",line,yytext);
}

{ASSIGNOP} {
	fprintf(token,"<ASSIGNOP,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <ASSIGNOP> Lexeme %s found\n",line,yytext);
}

{NOT} {
	fprintf(token,"<NOT,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <NOT> Lexeme %s found\n",line,yytext);
}

{LPAREN} {
	fprintf(token,"<LPAREN,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <LPAREN> Lexeme %s found\n",line,yytext);
}

{RPAREN} {
	fprintf(token,"<RPAREN,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <RPAREN> Lexeme %s found\n",line,yytext);
}

{LCURL} {
	fprintf(token,"<LCURL,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <LCURL> Lexeme %s found\n",line,yytext);
}

{RCURL} {
	fprintf(token,"<RCURL,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <RCURL> Lexeme %s found\n",line,yytext);
}

{LTHIRD} {
	fprintf(token,"<LTHIRD,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <LTHIRD> Lexeme %s found\n",line,yytext);
}

{RTHIRD} {
	fprintf(token,"<RTHIRD,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <RTHIRD> Lexeme %s found\n",line,yytext);
}

{COMMA} {
	fprintf(token,"<COMMA,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <COMMA> Lexeme %s found\n",line,yytext);
}

{SEMICOLON} {
	fprintf(token,"<SEMICOLON,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <SEMICOLON> Lexeme %s found\n",line,yytext);
}

{INTEGER_LITERAL} {
	fprintf(token,"<CONST_INT,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <CONST_INT> Lexeme %s found\n",line,yytext);
}

{FLOAT_LITERAL} {
	fprintf(token,"<CONST_FLOAT,%s>",yytext);
	fprintf(f_log,"Line no. %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",line,yytext);
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

	
	f_log=fopen("log.txt","w");
	token=fopen("token.txt","w");
	

	yyin=in;
	yylex();

	fclose(yyin);
	fclose(f_log);
	fclose(token);

	return 0;
}
