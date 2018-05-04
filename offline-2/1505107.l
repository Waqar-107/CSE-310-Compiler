%option noyywrap

/* definition section */
%{

#include<cstdio>
#include<cstdlib>
#include<string>
#include<iostream>
#include"1505107_SymbolTable.h"

using namespace std;

SymbolTable symbolTable(13);

FILE *logout;
FILE *tokenout;

int line=1;
int temp_line;
int cnt_err=0;

/* ----------------------------------------------- */
void printScopeTableFlex(string s,string t){
	bool f=symbolTable.Insert(s,t,logout);
	if(f)
		symbolTable.PrintCurrentScopeTable(logout);

	fprintf(logout,"\n");
}
/* ----------------------------------------------- */


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
	fprintf(tokenout,"<CONST_CHAR,%s>\n",ps.c_str());
	bool f=symbolTable.Insert(ps,"CONST_CHAR",logout);
	if(f)
		symbolTable.PrintCurrentScopeTable(logout);

	ps.clear();
	fprintf(logout,"\n");
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
	int len=s.length();

	char ch;
	string str="";

	fprintf(logout,"Line no. %d: Token <STRING> Lexeme %s found\n\n",line,yytext);
	fprintf(tokenout,"<String,%s>\n",str.c_str());
}
/* ----------------------------------------------- */
%}


DIGIT [0-9]
DIGITS {DIGIT}+
LETTER [a-zA-Z]
NEWLINE [\n]
WHITESPACE [ \t\r\v\f]+


/* ---------------------------------------------------------------------------------------- */
/* a single line starts with 'double slash' and ends with a newline.in the middle, 
   there can be literaly anything and any number of times.
   but if it has '\' and then '\n' it would be considered as muliline comment*/
/* ----------------------------------------------- */
SINGLE_LINE_COMMENT "//"[^\n]*
/* ---------------------------------------------------------------------------------------- */



/* ---------------------------------------------------------------------------------------- */
/* for a multiline comment, it must start with backslash-star and ends with star-backslash 
   in the middle there can be anything except star-backslash */
/* ----------------------------------------------- */
STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH \*[^\/]
ANYTHING_EXCEPT_STAR [^*]

MULTILINE_COMMENT ("/*")({ANYTHING_EXCEPT_STAR}|{STAR_FOLLOWED_BY_ANYTHING_EXCEPT_SLASH})*("*/")
/* ---------------------------------------------------------------------------------------- */
ANYTHING_EXCEPT_NL ([^\n])*
SLASH_FOLLWED_BY_NEWLINE ([\\])*[\n]
MULTILINE_COMMENT_2 [\/][\/]({ANYTHING_EXCEPT_NL}|{SLASH_FOLLWED_BY_NEWLINE})
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
/* Constants */

/* --------------------------------- */
INTEGER_LITERAL {DIGITS}
/* --------------------------------- */


/* --------------------------------- */
/* the exponential part is optional
   before that, there can be three variations
   digits.digits, .digits, digits */
/* --------------------------------- */   
EXPONENTIAL ([Ee][-+]?{DIGITS})
FLOAT_VAR_ONE ({DIGITS}\.{DIGITS})({EXPONENTIAL})?
FLOAT_VAR_TWO (\.{DIGITS})({EXPONENTIAL})?
FLOAT_VAR_THREE ({DIGITS})({EXPONENTIAL})?
FLOAT_LITERAL ({FLOAT_VAR_ONE}|{FLOAT_VAR_TWO}|{FLOAT_VAR_THREE})
/* --------------------------------- */


/* ---------------------------------
*  from ASCII 32 to 126 is printable 
*  32 is 'space', 126 is 'tilde'
*  special characters are, 
*  \n, \t, \\, \", \a, \f, \r, \b, \v, \0
*/
NORMAL_CHAR '([ -~]{-}['\\])'
SPECIAL_CHAR '(\\[nt\\afrbv0\"])'
CHAR_LITERAL {NORMAL_CHAR}|{SPECIAL_CHAR}
/* --------------------------------- */


/* --------------------------------- 
*  a string starts with a double quote, ends with a double qoute
*  between them there can be anything,in multiline string, there
*  will be a '\' and then a newline
*  --------------------------------*/
STRING \"(\\\n|[^"\n]|\\\")*\"
/* ----------------------------------------------- */

/* ----------------------------------------------- */
/* Identifiers */
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
/* ----------------------------------------------- */

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

UNFINISHED_CHAR_ERROR_ONE '({NORMAL_CHAR_FOR_ERR}|{SPECIAL_CHAR_FOR_ERR})
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
/*for a single line string, it will not finish using a "*/
UNFINISHED_STRING_VAR_ONE \"(\\\n|[^"\n]|\\\")*
UNFINISHED_STRING_VAR_TWO \"([^\\]\n|[^\n"]|[^\\]\")*\"
UNFINISHED_STRING {UNFINISHED_STRING_VAR_TWO}
/*----------------------------------------*/

/* rules section */
%%

{WHITESPACE} {
	//printf("ignoring space\n");
}

{NEWLINE} {
	line++;
}

{SINGLE_LINE_COMMENT} {
	fprintf(logout,"Line no. %d: Token <SINGLE_LINE_COMMENT> Lexeme %s found\n\n",line,yytext);
}

{MULTILINE_COMMENT} {
	countNewlineInComment(yytext);
	fprintf(logout,"Line no. %d to %d: Token <MULTI_LINE_COMMENT> Lexeme %s found\n\n",temp_line,line,yytext);

}

{BREAK} {
	fprintf(tokenout,"<BREAK>\n");
	fprintf(logout,"Line no. %d: Token <BREAK> Lexeme %s found\n\n",line,yytext);
}

{CASE} {
	fprintf(tokenout,"<CASE>\n");
	fprintf(logout,"Line no. %d: Token <CASE> Lexeme %s found\n\n",line,yytext);
}

{CHAR} {
	fprintf(tokenout,"<CHAR>\n");
	fprintf(logout,"Line no. %d: Token <CHAR> Lexeme %s found\n\n",line,yytext);
}

{CONTINUE} {
	fprintf(tokenout,"<CONTINUE>\n");
	fprintf(logout,"Line no. %d: Token <CONTINUE> Lexeme %s found\n\n",line,yytext);
}

{DEFAULT} {
	fprintf(tokenout,"<DEFAULT>\n");
	fprintf(logout,"Line no. %d: Token <DEFAULT> Lexeme %s found\n\n",line,yytext);
}

{DO} {
	fprintf(tokenout,"<DO>\n");
	fprintf(logout,"Line no. %d: Token <DO> Lexeme %s found\n\n",line,yytext);
}

{DOUBLE} {
	fprintf(tokenout,"<DOUBLE>\n");
	fprintf(logout,"Line no. %d: Token <DOUBLE> Lexeme %s found\n\n",line,yytext);
}

{ELSE} {
	fprintf(tokenout,"<ELSE>\n");
	fprintf(logout,"Line no. %d: Token <ELSE> Lexeme %s found\n\n",line,yytext);
}

{FLOAT} {
	fprintf(tokenout,"<FLOAT>\n");
	fprintf(logout,"Line no. %d: Token <FLOAT> Lexeme %s found\n\n",line,yytext);
}

{FOR} {
	fprintf(tokenout,"<FOR>\n");
	fprintf(logout,"Line no. %d: Token <FOR> Lexeme %s found\n\n",line,yytext);
}

{IF} {
	fprintf(tokenout,"<IF>\n");
	fprintf(logout,"Line no. %d: Token <IF> Lexeme %s found\n\n",line,yytext);
}

{INT} {
	fprintf(tokenout,"<INT>\n");
	fprintf(logout,"Line no. %d: Token <INT> Lexeme %s found\n\n",line,yytext);

}

{RETURN} {
	fprintf(tokenout,"<RETURN>\n");
	fprintf(logout,"Line no. %d: Token <RETURN> Lexeme %s found\n\n",line,yytext);
}

{SWITCH} {
	fprintf(tokenout,"<SWITCH>\n");
	fprintf(logout,"Line no. %d: Token <SWITCH> Lexeme %s found\n\n",line,yytext);
}

{WHILE} {
	fprintf(tokenout,"<WHILE>\n");
	fprintf(logout,"Line no. %d: Token <WHILE> Lexeme %s found\n\n",line,yytext);
}

{VOID} {
	fprintf(tokenout,"<VOID>\n");
	fprintf(logout,"Line no. %d: Token <VOID> Lexeme %s found\n\n",line,yytext);
}

{ADDOP} {
	fprintf(tokenout,"<ADDOP,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <ADDOP> Lexeme %s found\n\n",line,yytext);
}

{MULOP} {
	fprintf(tokenout,"<MULOP,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <MULOP> Lexeme %s found\n\n",line,yytext);
}

{RELOP} {
	fprintf(tokenout,"<RELOP,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <RELOP> Lexeme %s found\n\n",line,yytext);
}

{INCOP} {
	fprintf(tokenout,"<INCOP,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <INCOP> Lexeme %s found\n\n",line,yytext);
}

{LOGICOP} {
	fprintf(tokenout,"<LOGICOP,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <LOGICOP> Lexeme %s found\n\n",line,yytext);
}

{ASSIGNOP} {
	fprintf(tokenout,"<ASSIGNOP,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <ASSIGNOP> Lexeme %s found\n\n",line,yytext);
}

{NOT} {
	fprintf(tokenout,"<NOT,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <NOT> Lexeme %s found\n\n",line,yytext);
}

{LPAREN} {
	fprintf(tokenout,"<LPAREN,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <LPAREN> Lexeme %s found\n\n",line,yytext);
}

{RPAREN} {
	fprintf(tokenout,"<RPAREN,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <RPAREN> Lexeme %s found\n\n",line,yytext);
}

{LCURL} {
	fprintf(tokenout,"<LCURL,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <LCURL> Lexeme %s found\n\n",line,yytext);
}

{RCURL} {
	fprintf(tokenout,"<RCURL,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <RCURL> Lexeme %s found\n\n",line,yytext);
}

{LTHIRD} {
	fprintf(tokenout,"<LTHIRD,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <LTHIRD> Lexeme %s found\n\n",line,yytext);
}

{RTHIRD} {
	fprintf(tokenout,"<RTHIRD,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <RTHIRD> Lexeme %s found\n\n",line,yytext);
}

{COMMA} {
	fprintf(tokenout,"<COMMA,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <COMMA> Lexeme %s found\n\n",line,yytext);
}

{SEMICOLON} {
	fprintf(tokenout,"<SEMICOLON,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <SEMICOLON> Lexeme %s found\n\n",line,yytext);
}

{INTEGER_LITERAL} {
	fprintf(tokenout,"<CONST_INT,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <CONST_INT> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"CONST_INT");
}

{FLOAT_LITERAL} {
	fprintf(tokenout,"<CONST_FLOAT,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <CONST_FLOAT> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"CONST_FLOAT");
}

{CHAR_LITERAL} {
	fprintf(logout,"Line no. %d: Token <CONST_CHAR> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex_char(yytext);
}

{STRING} {
	processString(yytext);
}

{IDENTIFIER} {
	fprintf(tokenout,"<ID,%s>\n",yytext);
	fprintf(logout,"Line no. %d: Token <ID> Lexeme %s found\n\n",line,yytext);
	printScopeTableFlex(yytext,"ID");
}

{TOO_MANY_DECIMAL_POINTS_ERROR} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Too many decimal point error %s\n\n",line,yytext);
}

{VARIABLE_NAMING_ERROR} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Invalid prefix on ID or invalid suffix on Number %s\n\n",line,yytext);
}

{MULTI_CHAR_ERROR} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Multi character constant error %s\n\n",line,yytext);
}

{ILL_FORMED_NUM} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Ill formed numer: %s\n\n",line,yytext);
}

{UNFINISHED_CHAR_ERROR} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Unfinished character %s\n\n",line,yytext);
}

{UNRECOGNIZED_CHAR} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Unrecognized char %s\n\n",line,yytext);
}

{UNFINISHED_COMMENT} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Unfinished comment found %s\n\n",line,yytext);
}

{UNFINISHED_STRING} {
	cnt_err++;
	fprintf(logout,"Error at line. %d: Unfinished string found %s\n\n",line,yytext);
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

	
	logout=fopen("1505107_log.txt","w");
	tokenout=fopen("1505107_token.txt","w");
	

	yyin=in;
	yylex();

	//no. of total lines and erros
	fprintf(logout,"Total %d lines code read.\n\nTotal %d errors found\n\n",line,cnt_err);

	fclose(yyin);
	fclose(logout);
	fclose(tokenout);

	return 0;
}
