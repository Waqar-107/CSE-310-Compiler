
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

/* ----------------------------------------------- */
/* operators and punctuators */
ADDOP [+-]
MULOP [*/%]
INCOP ["++" | "--"]
RELOP ["<" | "<=" | ">" | ">=" | "==" | "!=" ]
ASSIGNOP [=]
LOGICOP ["&&" | "||"]
NOT [!]
LPAREN [(]
RPAREN [)]
LCURL [{]
RCURL [}]
LTHIRD ["["]
RTHIRD ["]"]
COMMA [,]
SEMICOLON [;]
/* ----------------------------------------------- */

/* rules section */
%%

{BREAK} {
	fprintf(f_log,"<BREAK>");
}

{CASE}{
	fprintf(f_log,"<CASE>");
}

{CHAR}{
	fprintf(f_log,"<CHAR>");
}

{CONTINUE}{
	fprintf(f_log,"<CONTINUE>");
}

{DEFAULT}{
	fprintf(f_log,"<DEFAULT>");
}

{DO}{
	fprintf(f_log,"<DO>");
}

{DOUBLE}{
	fprintf(f_log,"<DOUBLE>");
}

{ELSE}{
	fprintf(f_log,"<ELSE>");
}

{FLOAT}{
	fprintf(f_log,"<FLOAT>");
}

{FOR}{
	fprintf(f_log,"<FOR>");
}

{IF}{
	fprintf(f_log,"<IF>");
}

{INT}{
	fprintf(f_log,"<INT>");
}

{RETURN}{
	fprintf(f_log,"<RETURN>");
}

{SWITCH}{
	fprintf(f_log,"<SWITCH>");
}

{WHILE}{
	fprintf(f_log,"<WHILE>");
}

{VOID}{
	fprintf(f_log,"<VOID>");
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
