%option noyywrap

%{

#include<string>
#include<cstring>
#include "1505107_SymbolTable.h"
#include "y.tab.h"

using namespace std;

int line=1, temp_line, cnt_err=0;

/* ----------------------------------------------- */
void printScopeTableFlex_char(string s){

	char ch;
	string ps;
	
	//if length==3 then normal char, if 4, then \n,\t etc.
	if(s.length()==3)
		ch=s[1];

	else
	{
		int x,y;
		int ascii=(int)yytext[2];
		
		//char chr[]={'\n','\t','\\','\"','\a','\f','\r','\b','\v','\0'};

		if(s[2]=='n') {ch='\n';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\n');}
		else if(s[2]=='t') {ch='\t';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\t');}
		else if(s[2]=='a') {ch='\a';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\a');}
		else if(s[2]=='f') {ch='\f';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\f');}
		else if(s[2]=='r') {ch='\r';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\r');}
		else if(s[2]=='b') {ch='\b';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\b');}
		else if(s[2]=='v') {ch='\v';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\v');}
		else if(s[2]=='0') {ch='\0';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\0');}

		else if(s[2]=='\\') {ch='\\';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\t');}
		else if(s[2]=='\"') {ch='\"';fprintf(logout,"printing special char whose ascii is %d\n",(int)'\"');}
    		
	}

	ps.push_back(ch);
	ps.clear();
	
}
/* ----------------------------------------------- */


/* ----------------------------------------------- */
void countNewlineInComment(string s){
	temp_line=line;
	for(int i=1;i<s.length();i++){
		if(s[i]=='\n')
			line++;
	}
}
/* ----------------------------------------------- */


/* ----------------------------------------------- */
void processString(string s){
	
	temp_line=line;
	string str="";

	for(int i=0;i<s.length();i++){
		if(i+1<s.length() && s[i]=='\\' && s[i+1]=='\n')
			i++;
		else
			str.push_back(s[i]);
	}
}
/* ----------------------------------------------- */

%}


DIGIT [0-9]
DIGITS {DIGIT}+
LETTER [a-zA-Z]
NEWLINE [\n]
WHITESPACE [ \t\f\r\v]+


/* SINGLELINE-COMMENT */
/* ----------------------------------------------- */
SLASH_OR_SLASH_FOLLOWED_BY_NEWLINE ([\\]+([\n])?)?
ANYTHING_EXCEPT_NEWLINE [^\n]*
SINGLE_LINE_COMMENT2 "//"(([\\]+([\n])?)?|[^\n]*)*
SINGLE_LINE_COMMENT "//"({SLASH_OR_SLASH_FOLLOWED_BY_NEWLINE}|{ANYTHING_EXCEPT_NEWLINE})*
/* ---------------------------------------------------------------------------------------- */


/* MULTILINE-COMMENT */
/* ----------------------------------------------- */
STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH \*[^\/]
ANYTHING_EXCEPT_STAR [^*]

MULTILINE_COMMENT ("/*")({ANYTHING_EXCEPT_STAR}|{STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH})*("*/")
/* ---------------------------------------------------------------------------------------- */


/* ---------------------------------------------------------------------------------------- */
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
/* ---------------------------------------------------------------------------------------- */


/* ---------------------------------------------------------------------------------------- */
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
/* ---------------------------------------------------------------------------------------- */



/* ---------------------------------------------------------------------------------------- */

/* --------------------------------- */ 
/* INT */
INTEGER_LITERAL {DIGITS}
/* --------------------------------- */ 


/* --------------------------------- */  
/* FLOAT */ 
EXPONENTIAL ([Ee][-+]?{DIGITS})
FLOAT_VAR_ONE ({DIGITS}\.{DIGITS})({EXPONENTIAL})?
FLOAT_VAR_TWO (\.{DIGITS})({EXPONENTIAL})?
FLOAT_VAR_THREE ({DIGITS})({EXPONENTIAL})?
FLOAT_LITERAL ({FLOAT_VAR_ONE}|{FLOAT_VAR_TWO}|{FLOAT_VAR_THREE})
/* --------------------------------- */


/* --------------------------------- */
/* CHAR */
NORMAL_CHAR '([ -~]{-}['\\])'
SPECIAL_CHAR '(\\[nt\\afrbv0\"])'
CHAR_LITERAL {NORMAL_CHAR}|{SPECIAL_CHAR}
/* --------------------------------- */


/* --------------------------------- */
/* STRING */
SPC_FOR_STR (\\\n|\\\")
NORMAL_CHAR_FOR_STR [^\n\"]
STRING \"({SPC_FOR_STR}|{NORMAL_CHAR_FOR_STR})*\"
/* --------------------------------- */


/* --------------------------------- */
/* Identifiers */
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
/* --------------------------------- */

/* ---------------------------------------------------------------------------------------- */



/* ---------------------------------------------------------------------------------------- */
/* errors */

/*----------------------------------------*/
/*Too many decimal point error for character sequence like 1.2.345*/
FLOAT_VAR_ERR_TD1 ({DIGITS}\.{DIGITS})
FLOAT_VAR_TWO_TD2 (\.{DIGITS})
TOO_MANY_DECIMAL_POINTS_ERROR ({FLOAT_VAR_ERR_TD1}|{FLOAT_VAR_TWO_TD2})({FLOAT_VAR_ERR_TD1}|{FLOAT_VAR_TWO_TD2})*
/*----------------------------------------*/


/*----------------------------------------*/
/*invalid variable name*/
VARIABLE_NAMING_ERROR [0-9][a-zA-Z0-9_]*
/*----------------------------------------*/


/*----------------------------------------*/
/*multichar*/
NCCH ([ -~]{-}['\\])
SPCH (\\[nt\\afrbv0\"])
MULTI_CHAR_ERROR '(({NCCH}|{SPCH})*)'
/*----------------------------------------*/


/*----------------------------------------*/
/* ill formed number */
/* here exponential is a must, after E, there will be a FLOAT_LITERAL */
FLOAT_VAR_ONE_ERR ({DIGITS}\.{DIGITS})([Ee][-+]?)({FLOAT_LITERAL})
FLOAT_VAR_TWO_ERR (\.{DIGITS})([Ee][-+]?)({FLOAT_LITERAL})
FLOAT_VAR_THREE_ERR ({DIGITS})([Ee][-+]?)({FLOAT_LITERAL})
ILL_FORMED_NUM {FLOAT_VAR_ONE_ERR}|{FLOAT_VAR_TWO_ERR}|{FLOAT_VAR_THREE_ERR}
/*----------------------------------------*/


/*----------------------------------------*/
/* unfinished character */
NORMAL_CHAR_FOR_ERR ([ -~]{-}['\\])
SPECIAL_CHAR_FOR_ERR (\\[nt\\afrbv0\"])

UNFINISHED_CHAR_ERROR_ONE '({NORMAL_CHAR_FOR_ERR}|{SPECIAL_CHAR_FOR_ERR})*
SINGLE_FORWARD_SLASH_DETECTOR '[\\]'

UNFINISHED_CHAR_ERROR {UNFINISHED_CHAR_ERROR_ONE}|{SINGLE_FORWARD_SLASH_DETECTOR}
/*----------------------------------------*/


/*----------------------------------------*/
/* Unrecognized character */
UNRECOGNIZED_CHAR .
/*----------------------------------------*/


/*----------------------------------------*/
/* unfinished comment */
UNFINISHED_COMMENT ("/*")({ANYTHING_EXCEPT_STAR}|{STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH})*
/*----------------------------------------*/


/*----------------------------------------*/
/* unfinished string */
UNFINISHED_STRING (\"([^\"\n]|\\[\n])*)
/*----------------------------------------*/


/* rules section */
%%

{SINGLE_LINE_COMMENT} {
	countNewlineInComment(yytext);
}

{MULTILINE_COMMENT} {
	countNewlineInComment(yytext);
}

{BREAK} {
	
}

{CASE} {
	
}

{CHAR} {
	
}

{CONTINUE} {
	
}

{DEFAULT} {
	
}

{DO} {
	
}

{DOUBLE} {
	
}

{ELSE} {
	
}

{FLOAT} {
	
}

{FOR} {
	
}

{IF} {
	
}

{INT} {
	
}

{RETURN} {
	
}

{SWITCH} {
	
}

{WHILE} {
	
}

{VOID} {
	
}

{ADDOP} {
	
}

{MULOP} {
	
}

{RELOP} {
	
}

{INCOP} {
	
}

{LOGICOP} {
	
}

{ASSIGNOP} {
	
}

{NOT} {
	
}

{LPAREN} {
	
}

{RPAREN} {
	
}

{LCURL} {
	
}

{RCURL} {
	
}

{LTHIRD} {
	
}

{RTHIRD} {
	
}

{COMMA} {
	
}

{SEMICOLON} {
	
}

{INTEGER_LITERAL} {
	
}

{FLOAT_LITERAL} {
	
}

{CHAR_LITERAL} {
	
}

{STRING} {
	
}

{IDENTIFIER} {
	
}

{TOO_MANY_DECIMAL_POINTS_ERROR} {
	cnt_err++;
	
}

{VARIABLE_NAMING_ERROR} {
	cnt_err++;
	
}

{MULTI_CHAR_ERROR} {
	cnt_err++;
}

{ILL_FORMED_NUM} {
	cnt_err++;
}

{UNFINISHED_CHAR_ERROR} {
	cnt_err++;
}

{UNFINISHED_COMMENT} {
	cnt_err++;
}

{UNFINISHED_STRING} {
	cnt_err++;
}

{NEWLINE} {
	line++;
}

{WHITESPACE} {
	//printf("ignoring space\n");
}


%%
