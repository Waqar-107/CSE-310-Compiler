
//definition section
%{

#include<stdio.h>
#include<stdlib.h>

//declare other headers, variables, classes etc here.

%}



DIGIT [0-9]
LETTER [a-zA-Z]
NEWLINE \n
WHITESPACE [ \t\r\v\f]+
WORD [a-zA-Z]+


//rules section
%%

{WORD} {
	//write your code here
	//{WORD} is for example purpose, it can be replaced by others, and rules can be defined
	//here too. e.g: [a-zA-Z]+ {]
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

	/*open the files, globally declared e.g:
	* f_log=fopen("log.txt","w");
	* token=fopen("token.txt","w");
	*/

	yyin=in;
	yylex();

	fclose(yyin);
	//close the files which were opened for writing

	return 0;
}
