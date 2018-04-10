
/* definition section */
%{

#include<cstdio>
#include<cstdlib>


FILE *f_log;
FILE *token;

%}


DIGIT [0-9]
LETTER [a-zA-Z]
NEWLINE \n
WHITESPACE [ \t\r\v\f]+
WORD [a-zA-Z]+

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

/* rules section */
%%

{BREAK} {
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
	//close the files which were opened for writing

	return 0;
}
