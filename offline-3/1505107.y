%{
#include<iostream>
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<string>
#include "1505107_SymbolTable.h"

using namespace std;

int yyparse(void);
int yylex(void);

int cnt_err, semanticErr=0;
extern int line;
string variable_type;

extern FILE *yyin;
FILE *logout,*error;

SymbolTable table(22);

void yyerror(const char *s) {
	cnt_err++;
	fprintf(error,"syntax error \"%s\" Found on Line %d (Error no.%d)\n",s,line,cnt_err);
}

%}

%union{
	SymbolInfo *symbol;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE ASSIGNOP INCOP DECOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON COMMENT PRINTLN
%token<symbol>CONST_INT
%token<symbol>CONST_FLOAT
%token<symbol>CONST_CHAR 
%token<symbol>STRING
%token<symbol>ID
%token<symbol>ADDOP
%token<symbol>MULOP
%token<symbol>RELOP
%token<symbol>LOGICOP
%token<symbol>BITOP

%type<symbol>type_specifier

%define parse.error verbose
%%

start : program
		{
			fprintf(logout,"line no. %d: start : program\n\n",line);
		}
	;

program : program unit
		{
			fprintf(logout,"line no. %d: program : program unit\n\n",line);
		} 
	| unit
		{
			fprintf(logout,"line no. %d: unit\n\n",line);
		}
	;
	
unit : var_declaration
	  	{
		   	fprintf(logout,"line no. %d: unit : var_declation\n\n",line);
   	   	}
     | func_declaration
     	{
		   	fprintf(logout,"line no. %d: unit : func_declation\n\n",line);
   	   	}
     | func_definition
     	{
		   	fprintf(logout,"line no. %d: unit : func_declation\n\n",line);
   	   	}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			fprintf(logout,"line no. %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n",line);
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			fprintf(logout,"line no. %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n",line);
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		{
			fprintf(logout,"line no. %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",line);
		}
		| type_specifier ID LPAREN RPAREN compound_statement
		{
			fprintf(logout,"line no. %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n",line);
		}
 		;				


parameter_list : parameter_list COMMA type_specifier ID
		{
			fprintf(logout,"line no. %d: parameter_list : parameter_list COMMA type_specifier ID\n\n",line);
		}
		| parameter_list COMMA type_specifier
		{
			fprintf(logout,"line no. %d: parameter_list : parameter_list COMMA type_specifier\n\n",line);
		}
 		| type_specifier ID
 		{
			fprintf(logout,"line no. %d: parameter_list : type_specifier ID\n\n",line);
		}
		| type_specifier
		{
			fprintf(logout,"line no. %d: parameter_list : type_specifier\n\n",line);
		}
 		;

 		
compound_statement : LCURL statements RCURL
		{
			fprintf(logout,"line no. %d: compound_statement : LCURL statements RCURL\n\n",line);
		}
 		    | LCURL RCURL
 		{
			fprintf(logout,"line no. %d: compound_statement : LCURL RCURL\n\n",line);
		}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			fprintf(logout,"line no. %d: var_declaration : type_specifier declaration_list SEMICOLON\n\n",line);
		}
 		 ;
 		 
type_specifier : INT
		{
			fprintf(logout,"line no. %d: type_specifier : INT \n",line);
			variable_type = "INT";
			SymbolInfo *x = new SymbolInfo("INT");
			$$ = x;
			fprintf(logout,"%s\n\n",$$->getType());
		}
 		| FLOAT
 		{
			fprintf(logout,"line no. %d: type_specifier : FLOAT\n\n",line);
			variable_type="FLOAT";
		}
 		| VOID
 		{
			fprintf(logout,"line no. %d: type_specifier : VOID\n\n",line);
			variable_type="VOID";
		}
 		;
 		
declaration_list : declaration_list COMMA ID
		{
			fprintf(logout,"line no. %d: declaration_list : declaration_list COMMA ID\n",line);
			fprintf(logout,"%s %s\n\n",$3->getName().c_str(),$3->getName().c_str());
		}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		{
 			fprintf(logout,"line no. %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",line);
 			//fprintf(logout,"%s[%s]\n\n",$3->getName().c_str(),$5->getName());
 		}
 		  | ID
 		{
 			fprintf(logout,"line no. %d: declaration_list : ID\n",line);
 			fprintf(logout,"%s\n\n",$1->getName().c_str());

 			if(variable_type=="VOID") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else {
 				//insert in SymbolTable directly if not declared before
 				SymbolInfo *x=table.lookUp($1->getName());
 				if(x) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					table.Insert($1->getName(),$1->getType());
 				}
 			}
 			
 		}
 		  | ID LTHIRD CONST_INT RTHIRD
 		{
 			fprintf(logout,"line no. %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n",line);
 		}
 		  ;
 		  
statements : statement
		{
			fprintf(logout,"line no. %d: statements : statement\n\n",line);
		}
	   | statements statement
	    {
			fprintf(logout,"line no. %d: statements : statements statement\n\n",line);
		}
	   ;
	   
statement : var_declaration
		{
			fprintf(logout,"line no. %d: statement : var_declaration\n\n",line);
		}
	  | expression_statement
	  	{
			fprintf(logout,"line no. %d: statement : expression_statement\n\n",line);
		}
	  | compound_statement
	  	{
			fprintf(logout,"line no. %d: statement : compound_statement\n\n",line);
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  	{
			fprintf(logout,"line no. %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",line);
		}
	  | IF LPAREN expression RPAREN statement
	  	{
			fprintf(logout,"line no. %d: statement : IF LPAREN expression RPAREN statement\n\n",line);
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
	  	{
			fprintf(logout,"line no. %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n\n",line);
		}
	  | WHILE LPAREN expression RPAREN statement
		{
			fprintf(logout,"line no. %d: statement : WHILE LPAREN expression RPAREN statement\n\n",line);
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  	{
			fprintf(logout,"line no. %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",line);
		}
	  | RETURN expression SEMICOLON
	    {
			fprintf(logout,"line no. %d: statement : RETURN expression SEMICOLON\n\n",line);
		}
	  ;
	  
expression_statement : SEMICOLON
		{
			fprintf(logout,"line no. %d: expression_statement : SEMICOLON\n\n",line);
		}			
			| expression SEMICOLON
		{
			fprintf(logout,"line no. %d: expression_statement : expression SEMICOLON\n\n",line);
		} 
			;
	  
variable : ID
		{
			fprintf(logout,"line no. %d: variable : ID\n\n",line);
		} 		
	 | ID LTHIRD expression RTHIRD 
		{
			fprintf(logout,"line no. %d: variable : ID LTHIRD expression RTHIRD\n\n",line);
		}
	 ;
	 
 expression : logic_expression
		{
			fprintf(logout,"line no. %d: expression : logic_expression\n\n",line);
		}	
	   | variable ASSIGNOP logic_expression 	
		{
			fprintf(logout,"line no. %d: expression : variable ASSIGNOP logic_expression\n\n",line);
		}
	   ;
			
logic_expression : rel_expression
		{
			fprintf(logout,"line no. %d: logic_expression : rel_expression\n\n",line);
		} 	
		 | rel_expression LOGICOP rel_expression 	
		{
			fprintf(logout,"line no. %d: logic_expression : rel_expression LOGICOP rel_expression\n\n",line);
		}
		 ;
			
rel_expression : simple_expression 
		{
			fprintf(logout,"line no. %d: rel_expression : simple_expression\n\n",line);
		}
		| simple_expression RELOP simple_expression	
		{
			fprintf(logout,"line no. %d: rel_expression : simple_expression RELOP simple_expression	\n\n",line);
		}
		;
				
simple_expression : term
		{
			fprintf(logout,"line no. %d: simple_expression : term\n\n",line);
		} 
		  | simple_expression ADDOP term
		{
			fprintf(logout,"line no. %d: simple_expression : simple_expression ADDOP term\n\n",line);
		} 
		  ;
					
term :	unary_expression
		{
			fprintf(logout,"line no. %d: term : unary_expression\n\n",line);
		}
     |  term MULOP unary_expression
		{
			fprintf(logout,"line no. %d: term : term MULOP unary_expression\n\n",line);
		}
     ;

unary_expression : ADDOP unary_expression
		{
			fprintf(logout,"line no. %d: unary_expression : ADDOP unary_expression\n\n",line);
		}  
		 | NOT unary_expression 
		{
			fprintf(logout,"line no. %d: unary_expression NOT unary_expression\n\n",line);
		}
		 | factor 
		{
			fprintf(logout,"line no. %d: unary_expression factor\n\n",line);
		}
		 ;
	
factor	: variable
		{
			fprintf(logout,"line no. %d: factor	: variable\n\n",line);
		} 
	| ID LPAREN argument_list RPAREN
		{
			fprintf(logout,"line no. %d: factor	: ID LPAREN argument_list RPAREN\n\n",line);
		}
	| LPAREN expression RPAREN
		{
			fprintf(logout,"line no. %d: factor	: LPAREN expression RPAREN\n\n",line);
		}
	| CONST_INT
		{
			fprintf(logout,"line no. %d: factor	: CONST_INT\n\n",line);
		} 
	| CONST_FLOAT
		{
			fprintf(logout,"line no. %d: factor	: CONST_FLOAT\n\n",line);
		}
	| variable INCOP
		{
			fprintf(logout,"line no. %d: factor	: variable INCOP\n\n",line);
		} 
	| variable DECOP
		{
			fprintf(logout,"line no. %d: factor	: variable DECOP\n\n",line);
		}
	;
	
argument_list : arguments
		{
			fprintf(logout,"line no. %d: argument_list : arguments\n\n",line);
		}
			  |
			  ;
	
arguments : arguments COMMA logic_expression
		{
			fprintf(logout,"line no. %d: arguments : arguments COMMA logic_expression\n\n",line);
		}
	      | logic_expression
	    {
			fprintf(logout,"line no. %d: arguments : logic_expression\n\n",line);
		}
	      ;
 

%%
int main(int argc,char *argv[])
{

	if((yyin=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logout= fopen(argv[2],"w");
	fclose(logout);

	error= fopen(argv[3],"w");
	fclose(error);
	
	logout= fopen(argv[2],"a");
	error= fopen(argv[3],"a");
	
	cnt_err=0;
	yyparse();

	//print the SymbolTable and other credentials
	table.PrintAllScopeTable(logout);
	fprintf(logout,"total lines read: %d\n",line-1);
	fprintf(logout,"total errors encountered: %d",cnt_err+semanticErr);

	fclose(logout);
	fclose(error);
	
	return 0;
}

