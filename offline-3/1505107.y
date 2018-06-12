%{
#include<iostream>
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include <limits>
#include<string>
#include<vector>
#include<algorithm>
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

string codes;
vector<string> code_list;
vector<string> statement_list;

void yyerror(const char *s) {
	cnt_err++;
	fprintf(error,"syntax error \"%s\" Found on Line %d (Error no.%d)\n",s,line,cnt_err);
}

string stoi(int n){
	string temp;
	while(n){
		int r=n%10;
		n/=10;
		temp.push_back(r+48);
	}

	reverse(temp.begin(),temp.end());
	return temp;
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

%type<symbol>type_specifier parameter_list declaration_list var_declaration unit func_declaration statement statements variable expression factor arguments argument_list expression_statement unary_expression simple_expression logic_expression rel_expression term
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%define parse.error verbose

%%

start : program
		{
			fprintf(logout,"line no. %d: start : program\n",line);
			
			for(int i=0;i<code_list.size();i++)
				fprintf(logout,"%s\n",code_list[i].c_str());

			fprintf(logout,"\n");
		}
	;

program : program unit
		{
			fprintf(logout,"line no. %d: program : program unit\n",line);
			
			code_list.push_back($2->getName());
			
			for(int i=0;i<code_list.size();i++)
				fprintf(logout,"%s\n",code_list[i].c_str());

			fprintf(logout,"\n");
		} 
	| unit
		{
			fprintf(logout,"line no. %d: program : unit\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			code_list.push_back($1->getName());
		}
	;
	
unit : var_declaration
	  	{
		   	fprintf(logout,"line no. %d: unit : var_declation\n",line);
		   	fprintf(logout,"%s\n\n",$1->getName().c_str());

		   	SymbolInfo *x=new SymbolInfo($1->getName(),"unit");
		   	$$=x;
   	   	}
     | func_declaration
     	{
		   	fprintf(logout,"line no. %d: unit : func_declation\n",line);
		   	fprintf(logout,"%s\n\n",$1->getName().c_str());

		   	SymbolInfo *x=new SymbolInfo($1->getName(),"unit");
		   	$$=x;
   	   	}
     | func_definition
     	{
		   	fprintf(logout,"line no. %d: unit : func_declation\n",line);
		   	
   	   	}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			fprintf(logout,"line no. %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n",line);
			
			//int foo(int a,float b);
			table.Insert($2->getName(),"function");
			
			SymbolInfo *x=table.lookUp($2->getName());
			x->setReturnType($1->getType());
			
			codes="";
			codes+=($1->getType()+" "+$2->getName()+"(");
			for(int i=0;i<$4->edge.size();i++){
				x->edge.push_back($4->edge[i]);
				codes+=($4->edge[i]->getType()+" "+$4->edge[i]->getName());
			}

			fprintf(logout,"%s)\n\n",codes.c_str());
			
			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_declaration");
			$$=newSymbol;
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			fprintf(logout,"line no. %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n",line);

			//int foo();
			table.Insert($2->getName(),"function");
			
			SymbolInfo *x=table.lookUp($2->getName());
			x->setReturnType($1->getType());
			
			codes="";
			codes+=($1->getType()+" "+$2->getName()+"();");

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_declaration");
			$$=newSymbol;
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
			fprintf(logout,"line no. %d: parameter_list : parameter_list COMMA type_specifier ID\n",line);

			$$->edge.push_back(new SymbolInfo($4->getName(),$3->getType()));
			for(int i=0;i<$$->edge.size();i++){
				fprintf(logout,"%s %s",$$->edge[i]->getType().c_str(),$$->edge[i]->getName().c_str());
				if(i<$$->edge.size()-1)
					fprintf(logout,",");
			}

			fprintf(logout,"\n\n");
		}
		| parameter_list COMMA type_specifier
		{
			fprintf(logout,"line no. %d: parameter_list : parameter_list COMMA type_specifier\n\n",line);

			$$->edge.push_back(new SymbolInfo("",$3->getType()));
			for(int i=0;i<$$->edge.size();i++){
				fprintf(logout,"%s %s",$$->edge[i]->getType().c_str(),$$->edge[i]->getName().c_str());
				if(i<$$->edge.size()-1)
					fprintf(logout,",");
			}

			fprintf(logout,"\n\n");
		}
 		| type_specifier ID
 		{
			fprintf(logout,"line no. %d: parameter_list : type_specifier ID\n\n",line);

			SymbolInfo *x=new SymbolInfo("parameter_list");
			$$=x;

			//edge is the list or parameters where each parameter has id-name and type
			$$->edge.push_back(new SymbolInfo($2->getName(),$1->getType()));
			fprintf(logout,"%s %s\n\n",$1->getType().c_str(),$2->getName().c_str());
		}
		| type_specifier
		{
			fprintf(logout,"line no. %d: parameter_list : type_specifier\n\n",line);
			SymbolInfo *x=new SymbolInfo("parameter_list");
			$$=x;

			//edge is the list or parameters where each parameter has id-name and type
			$$->edge.push_back(new SymbolInfo("",$1->getType()));
			fprintf(logout,"%s\n\n",$1->getType().c_str());
		}
 		;

 		
compound_statement : LCURL statements RCURL
		{
			fprintf(logout,"line no. %d: compound_statement : LCURL statements RCURL\n",line);
			fprintf(logout,"{%s}\n\n",$2->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo("{"+$2->getName()+"}",compound_statement);
			$$=newSymbol;
		}
 		    | LCURL RCURL
 		{
			fprintf(logout,"line no. %d: compound_statement : LCURL RCURL\n",line);
			fprintf(logout,"{}");

			SymbolInfo *newSymbol=new SymbolInfo("{}",compound_statement);
			$$=newSymbol;
		}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			fprintf(logout,"line no. %d: var_declaration : type_specifier declaration_list SEMICOLON\n",line);
			fprintf(logout,"%s ",$1->getType().c_str());
			
			codes="";
			codes += $1->getType()+" ";

			//print the declaration_list
			for(int i=0;i<$2->edge.size();i++){
				fprintf(logout,"%s",$2->edge[i]->getName().c_str());
				codes += $2->edge[i]->getName();
				if($2->edge[i]->sz>0)
					fprintf(logout,"[%d]",$2->edge[i]->sz), codes+="["+stoi($2->edge[i]->sz)+"]";
				if(i<$2->edge.size()-1)
					fprintf(logout,","), codes+=",";
			}

			fprintf(logout,";\n\n");
			codes+=";";

			SymbolInfo *newSymbol=new SymbolInfo(codes,"var_declaration");
			$$=newSymbol;

			$2->edge.clear();
		}
 		 ;
 		 
type_specifier : INT
		{
			fprintf(logout,"line no. %d: type_specifier : INT \n",line);
			variable_type = "INT";

			SymbolInfo *newSymbol = new SymbolInfo("int");
			$$ = newSymbol;
			fprintf(logout,"%s\n\n",$$->getType().c_str());
		}
 		| FLOAT
 		{
			fprintf(logout,"line no. %d: type_specifier : FLOAT\n",line);
			variable_type="FLOAT";

			SymbolInfo *newSymbol = new SymbolInfo("float");
			$$ = newSymbol;
			fprintf(logout,"%s\n\n",$$->getType().c_str());
		}
 		| VOID
 		{
			fprintf(logout,"line no. %d: type_specifier : VOID\n",line);
			variable_type="VOID";

			SymbolInfo *newSymbol = new SymbolInfo("void");
			$$ = newSymbol;
			fprintf(logout,"%s\n\n",$$->getType().c_str());
		}
 		;
 		
declaration_list : declaration_list COMMA ID
		{
			fprintf(logout,"line no. %d: declaration_list : declaration_list COMMA ID\n",line);
			$$->edge.push_back($3);

			//print the declaration_list
			for(int i=0;i<$$->edge.size();i++){
				fprintf(logout,"%s",$$->edge[i]->getName().c_str());
				if($$->edge[i]->sz>0)
					fprintf(logout,"[%d]",$$->edge[i]->sz);
				
				if(i<$$->edge.size()-1)
					fprintf(logout,",");
				else
					fprintf(logout,"\n\n");
			}
			
			//---------------------------------------------------------------------------
			//semantics and insertion in the table
 			if(variable_type=="VOID") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else {
 				//insert in SymbolTable directly if not declared before
 				SymbolInfo *x=table.lookUp($3->getName());
 				if(x) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					table.Insert($3->getName(),variable_type);
 				}
 			}
 			//---------------------------------------------------------------------------

		}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		{
 			fprintf(logout,"line no. %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",line);

 			//print the declaration_list
			for(int i=0;i<$$->edge.size();i++){
				fprintf(logout,"%s,",$$->edge[i]->getName().c_str());
			}

			fprintf(logout,"%s[%s]\n\n",$3->getName().c_str(),$5->getName());
			$$->edge.push_back($3);
 			

			//---------------------------------------------------------------------------
			//semantics and insertion in the table
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
 					//table.Insert($3->getName(),variable_type);
 					//x=table.lookUp($3->getName());
 					x->sz=atoi($5->getName().c_str());
 				}
 			}
 			//---------------------------------------------------------------------------

 		}
 		  | ID
 		{
 			fprintf(logout,"line no. %d: declaration_list : ID\n",line);
 			fprintf(logout,"%s\n\n",$1->getName().c_str());

 			SymbolInfo *x = new SymbolInfo("declaration_list");
 			$$ = x;

 			//---------------------------------------------------------------------------
			//semantics and insertion in the table
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
 					//table.Insert($1->getName(),$1->getType());
 					$$->edge.push_back($1);
 				}
 			}
 			//---------------------------------------------------------------------------
 		}
 		  | ID LTHIRD CONST_INT RTHIRD
 		{
 			fprintf(logout,"line no. %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n",line);
 			fprintf(logout,"%s[%s]\n\n",$1->getName().c_str(),$3->getName().c_str());

 			SymbolInfo *x = new SymbolInfo("declaration_list");
 			$$ = x;
 			$1->sz=atoi($3->getName().c_str());
 			$$->edge.push_back($1);

 			//---------------------------------------------------------------------------
			//semantics and insertion in the table
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
 					x=table.lookUp($1->getName());
 					x->sz=atoi($3->getName().c_str());
 				}
 			}
 			//---------------------------------------------------------------------------
 		}
 		  ;
 		  
statements : statement
		{
			fprintf(logout,"line no. %d: statements : statement\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo("statements","statements");
			newSymbol->edge.push_back($1);
			$$=newSymbol;
		}
	   | statements statement
	    {
			fprintf(logout,"line no. %d: statements : statements statement\n",line);
		
			$1->edge.push_back($2);
			for(int i=0;i<$1->edge.size();i++){
				fprintf(logout,"%s\n",$1->edge[i]->getName().c_str());
			}

			fprintf(logout,"\n");
		}
	   ;
	   
statement : var_declaration
		{
			fprintf(logout,"line no. %d: statement : var_declaration\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"statement");
			$$=newSymbol;
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
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
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
			fprintf(logout,"line no. %d: expression_statement : SEMICOLON\n",line);
			fprintf(logic_expression,";\n\n");

			SymbolInfo *newSymbol=new SymbolInfo(";","expression_statement");
			$$=newSymbol;
		}			
			| expression SEMICOLON
		{
			fprintf(logout,"line no. %d: expression_statement : expression SEMICOLON\n",line);
			fprintf(logout,"%s;\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+";","expression_statement");
			$$=newSymbol;
		} 
			;
	  
variable : ID
		{
			fprintf(logout,"line no. %d: variable : ID\n",line);
			fprintf(logout,"%s\n\n",$1->getName());

			$$=$1;
		} 		
	 | ID LTHIRD expression RTHIRD 
		{
			fprintf(logout,"line no. %d: variable : ID LTHIRD expression RTHIRD\n",line);
			fprintf(logout,"%s[%d]\n\n",$1->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"["+$3->getName()+"]","variable");
			$$=newSymbol;
		}
	 ;
	 
 expression : logic_expression
		{
			fprintf(logout,"line no. %d: expression : logic_expression\n",line);
			fprintf(logout,"%s\n\n",$1->getName());

			$$=$1;
		}	
	   | variable ASSIGNOP logic_expression 	
		{//semantic error check dite hbe
			fprintf(logout,"line no. %d: expression : variable ASSIGNOP logic_expression\n",line);
			fprintf(logout,"%s=%s\n\n",$1->getName().c_str(),$3->getName());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"="+$3->getName(),"expression");
			$$=newSymbol;
		}
	   ;
			
logic_expression : rel_expression
		{
			fprintf(logout,"line no. %d: logic_expression : rel_expression\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());
			$$=$1;
		} 	
		 | rel_expression LOGICOP rel_expression 	
		{
			fprintf(logout,"line no. %d: logic_expression : rel_expression LOGICOP rel_expression\n",line);
			fprintf(logout,"%s%s%s\n\n",$1->getName().c_str(),$2->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"logic_expression");
			$$=newSymbol;
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
			fprintf(logout,"line no. %d: simple_expression : term\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"simple_expression");
			$$=newSymbol;
		} 
		  | simple_expression ADDOP term
		{
			fprintf(logout,"line no. %d: simple_expression : simple_expression ADDOP term\n",line);
			fprintf(logout,"%s%s%s\n\n",$1->getName().c_str(),$2->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"simple_expression");
			$$=newSymbol;
		} 
		  ;
					
term :	unary_expression
		{
			fprintf(logout,"line no. %d: term : unary_expression\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"term");
			$$=newSymbol;
		}
     |  term MULOP unary_expression
		{
			fprintf(logout,"line no. %d: term : term MULOP unary_expression\n",line);
			fprintf(logout,"%s%s%s\n\n",$1->getName().c_str(),$2->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"term");
			$$=newSymbol;
		}
     ;

unary_expression : ADDOP unary_expression
		{
			fprintf(logout,"line no. %d: unary_expression : ADDOP unary_expression\n",line);
			fprintf(logout,"%s%s\n\n",$1->getName().c_str(),$2->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName(),"unary_expression");
			$$=newSymbol;
		}  
		 | NOT unary_expression 
		{
			fprintf(logout,"line no. %d: unary_expression NOT unary_expression\n",line);
			fprintf(logout,"!%s\n\n",$2->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo("!"+$2->getName(),"unary_expression");
			$$=newSymbol;
		}
		 | factor 
		{
			fprintf(logout,"line no. %d: unary_expression factor\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			$$=$1;
		}
		 ;
	
factor	: variable
		{
			fprintf(logout,"line no. %d: factor	: variable\n",line);
			fprintf(logout,"%s\n\n",$$->getName().c_str());
			$$=$1;
		} 
	| ID LPAREN argument_list RPAREN
		{
			fprintf(logout,"line no. %d: factor	: ID LPAREN argument_list RPAREN\n",line);
			fprintf(logout,"%s(%s)\n\n",$1->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"("+$3->getName()+")","factor");
			$$=newSymbol;
		}
	| LPAREN expression RPAREN
		{
			fprintf(logout,"line no. %d: factor	: LPAREN expression RPAREN\n",line);
			fprintf(logout,"(%s)\n\n",$2->getName().c_str());
			
			SymbolInfo *newSymbol=new SymbolInfo("("+$2->getName()+")","factor");
			$$=newSymbol;
		}
	| CONST_INT
		{
			fprintf(logout,"line no. %d: factor	: CONST_INT\n",line);
			fprintf(logout,"%s\n\n",$1->getName());
			$$=$1;
		} 
	| CONST_FLOAT
		{
			fprintf(logout,"line no. %d: factor	: CONST_FLOAT\n",line);
			fprintf(logout,"%s\n\n",$1->getName());
			$$=$1;
		}
	| variable INCOP
		{
			fprintf(logout,"line no. %d: factor	: variable INCOP\n",line);
			fprintf(logout,"%s++",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"++","factor");
			$$=newSymbol;
		} 
	| variable DECOP
		{
			fprintf(logout,"line no. %d: factor	: variable DECOP\n",line);
			fprintf(logout,"%s--",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"--","factor");
			$$=newSymbol;
		}
	;
	
argument_list : arguments
		{
			fprintf(logout,"line no. %d: argument_list : arguments\n",line);
			fprintf(logout,"%s\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"argument_list");
			$$=newSymbol;
		}
	|
			  ;
	
arguments : arguments COMMA logic_expression
		{
			fprintf(logout,"line no. %d: arguments : arguments COMMA logic_expression\n\n",line);
			fprintf(logout,"%s,%s\n\n",$1->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+","+$3->getName(),"arguments");
			$$=newSymbol;
		}
	      | logic_expression
	    {
			fprintf(logout,"line no. %d: arguments : logic_expression\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"arguments");
			$$=newSymbol;
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

