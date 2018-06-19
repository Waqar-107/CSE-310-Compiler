%{
#include<iostream>
#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<cmath>
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

SymbolTable table(10);

string codes;
vector<string> code_list;
vector<string> statement_list;
vector<SymbolInfo*> params;
vector<SymbolInfo*> var_list;
SymbolInfo *currentFunction;
bool isReturning;

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

void fillScopeWithParams(){
	for(int i=0;i<params.size();i++)
	{
		if(!table.Insert(params[i]->getName(),"ID",logout)){
			semanticErr++;
			fprintf(error,"semantic error found on line %d: id already declared\n\n",line);
		}

		else{
			SymbolInfo *temp=table.lookUp(params[i]->getName());
			temp->setVariableType(params[i]->getVariableType());
			temp->sz=params[i]->sz;
		}
	}

	params.clear();
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

%type<symbol>compound_statement type_specifier parameter_list declaration_list var_declaration unit func_declaration statement statements variable expression factor arguments argument_list expression_statement unary_expression simple_expression logic_expression rel_expression term func_definition
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
		   	fprintf(logout,"line no. %d: unit : func_declaration\n",line);
		   	fprintf(logout,"%s\n\n",$1->getName().c_str());

		   	SymbolInfo *x=new SymbolInfo($1->getName(),"unit");
		   	$$=x;
   	   	}
     | func_definition
     	{
		   	fprintf(logout,"line no. %d: unit : func_declaration\n",line);
		   	fprintf(logout,"%s\n\n",$1->getName().c_str());

		   	SymbolInfo *x=new SymbolInfo($1->getName(),"unit");
		   	$$=x;
   	   	}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			fprintf(logout,"line no. %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n",line);
			
			//int foo(int a,float b);
			if(!table.Insert($2->getName(),"ID",logout)){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: redeclaration of function \'%s\'\n\n",line,$2->getName().c_str());
			}

			else{
				SymbolInfo *x=table.lookUp($2->getName());
				x->setReturnType($1->getType());
				x->setIdentity("function_declaration");

				for(int i=0;i<$4->edge.size();i++){
					x->edge.push_back($4->edge[i]);
					x->edge[i]->setIdentity("params");
				}
			}
			
			codes="";
			codes+=($1->getType()+" "+$2->getName()+"(");
			for(int i=0;i<$4->edge.size();i++){
				codes+=($4->edge[i]->getType()+" "+$4->edge[i]->getName());
				if(i<$4->edge.size()-1)
					codes+=",";
			}
			codes+=")";

			fprintf(logout,"%s)\n\n",codes.c_str());
			
			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_declaration");
			$$=newSymbol;
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			fprintf(logout,"line no. %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n",line);

			//int foo();
			if(!table.Insert($2->getName(),"ID",logout)){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: redeclaration of function \'%s\'\n\n",line,$2->getName().c_str());	
			}

			else{
				SymbolInfo *x=table.lookUp($2->getName());
				x->setReturnType($1->getType());
				x->setIdentity("function_declaration");
			}
			
			codes="";
			codes+=($1->getType()+" "+$2->getName()+"();");

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_declaration");
			$$=newSymbol;
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN{table.EnterScope(logout);fillScopeWithParams();} compound_statement
		{
			fprintf(logout,"line no. %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n",line);

			codes=$1->getType()+" ";
			codes+=$2->getName(); codes+="(";
			for(int i=0;i<$4->edge.size();i++){
				codes+=$4->edge[i]->getType()+" "+$4->edge[i]->getName();
			}

			codes+=")";
			codes+=$7->getName();

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_definition");
			$$=newSymbol;

			//------------------------------------------
			//current scope obtained, insert the function in the global scope
			int id=table.getCurrentID();
			var_list=table.printCurrentAndGetAll(logout);
			table.ExitScope(logout);
			//------------------------------------------

			//-----------------------------------------------------------------------
			//semantic error: type_specifier void and return
			if(isReturning && $1->getType()=="void"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: type-specifier is of type void, can't return\n\n",line);
			}

			else if(!isReturning && $1->getType()!="void"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: missing return statement\n\n",line);
			}

			isReturning=false;
			//-----------------------------------------------------------------------

			/*check if the function has been declared previously or not
			if yes then match the parameter_list, else insert it and also update
			current function pointer, later before exiting the scope of this function
			insert all the variables in the vector*/
			SymbolInfo *x=table.lookUp($2->getName());
			
			if(x){
				if(x->getIdentity()!="function_declaration"){
					semanticErr++;
					fprintf(error,"semantic error found on line %d: function with same name already defined\n\n",line);
				}

				else{
					//declared before
					//check parameter names and their variable types
			
					if(x->edge.size()!=$4->edge.size()){
						fprintf(error,"semantic error in line %d: parameters didn't match from the previously declared one\n\n",line);
						semanticErr++;
					}

					else{
						//first  match params
						bool f=1;
						for(int i=0;i<$4->edge.size();i++){
							if($4->edge[i]->getName()!=x->edge[i]->getName() || $4->edge[i]->getType()!=x->edge[i]->getType()){
								f=0;
								break;
							}
						}

						if(f){
							//match return type
							if(x->getReturnType()==$1->getType()){
								//already inserted and parameters matched, edit it
								x->setIdentity("func_defined");
								currentFunction=x;

								for(int i=0;i<var_list.size();i++){
									x->edge.push_back(var_list[i]);
								}

								currentFunction=x;cout<<var_list.size()<<" "<<$2->getName()<<endl;
							}

							else{
								semanticErr++;
								fprintf(error,"semantic error found in line %d: return type didn't match with the previous declaration\n\n",line);
							}
						}

						else{
							semanticErr++;
							fprintf(error,"semantic error found in line %d: parameter list didn't match\n\n",line);
						}
					}
				}
			}

			else{
				table.Insert($2->getName(),"ID",logout);
				x=table.lookUp($2->getName());
				x->setIdentity("func_defined");
				x->setVariableType($1->getType());
				
				for(int i=0;i<var_list.size();i++){
					x->edge.push_back(var_list[i]);
				}

				currentFunction=x;cout<<var_list.size()<<" "<<$2->getName()<<endl;
			}

			//exit new scope created by a function
			table.PrintAllScopeTable(logout);

			//give exit message
			fprintf(logout,"################################\n");
			fprintf(logout,"# ScopeTable with ID %d Removed #\n",id);
			fprintf(logout,"################################\n\n");

			var_list.clear();
		}
		| type_specifier ID LPAREN RPAREN{table.EnterScope(logout);} compound_statement
		{
			fprintf(logout,"line no. %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n",line);

			codes=$1->getType()+" ";
			codes+=$2->getName();codes+="()";codes+=$6->getName();

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_definition");
			$$=newSymbol;

			//------------------------------------------
			//current scope obtained, insert the function in the global scope
			int id=table.getCurrentID();
			var_list=table.printCurrentAndGetAll(logout);
			table.ExitScope(logout);
			//------------------------------------------

			//-----------------------------------------------------------------------
			//semantic error: type_specifier void and return
			if(isReturning && $1->getType()=="void"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: type-specifier is of type void, can't return\n\n",line);
			}

			else if(!isReturning && $1->getType()!="void"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: missing return statement\n\n",line);
			}

			isReturning=false;
			//-----------------------------------------------------------------------

			/*check if the function has been declared previously or not
			if yes then match the parameter_list, else insert it and also update
			current function pointer, later before exiting the scope of this function
			insert all the variables in the vector*/
			SymbolInfo *x=table.lookUp($2->getName());

			if(x){
				if(x->getIdentity()!="function_declaration"){
					semanticErr++;
					fprintf(error,"semantic error found on line %d: function with same name already defined\n\n",line);
				}

				else{
					if(x->edge.size()>0){
						semanticErr++;
						fprintf(error,"semantic error found on line %d: parameter quantity does not match with declarations\n\n",line);
					}

					else{
						//match return type
						if(x->getReturnType()==$1->getType()){
							//already inserted and parameters matched, edit it
							x->setIdentity("func_defined");
							currentFunction=x;

							for(int i=0;i<var_list.size();i++){
								x->edge.push_back(var_list[i]);
							}

							currentFunction=x;cout<<var_list.size()<<" "<<$2->getName()<<endl;
						}

						else{
							semanticErr++;
							fprintf(error,"semantic error found in line %d: return type didn't match with the previous declaration\n\n",line);
						}
					}
				}
			}

			else{
				table.Insert($2->getName(),"ID",logout);
				x=table.lookUp($2->getName());
				x->setIdentity("func_defined");
				
				for(int i=0;i<var_list.size();i++){
					x->edge.push_back(var_list[i]);
				}

				currentFunction=x;cout<<var_list.size()<<" "<<$2->getName()<<endl;
				x->setVariableType($1->getType());
			}

			//exit new scope created by a function
			table.PrintAllScopeTable(logout);

			//give exit message
			fprintf(logout,"################################\n");
			fprintf(logout,"# ScopeTable with ID %d Removed #\n",id);
			fprintf(logout,"################################\n\n");

			var_list.clear();
		}
 		;				


parameter_list : parameter_list COMMA type_specifier ID
		{
			fprintf(logout,"line no. %d: parameter_list : parameter_list COMMA type_specifier ID\n",line);

			$$->edge.push_back(new SymbolInfo($4->getName(),$3->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("param");

			for(int i=0;i<$$->edge.size();i++){
				fprintf(logout,"%s %s",$$->edge[i]->getType().c_str(),$$->edge[i]->getName().c_str());
				if(i<$$->edge.size()-1)
					fprintf(logout,",");
			}

			fprintf(logout,"\n\n");

			//--------------------------------------------------------------------
			//insert in the current scope, already a new scope has been created
			//we insert in params for now, later we will insert them in the table
			SymbolInfo *temp=new SymbolInfo($4->getName(),"ID");

			int n;
			temp->sz=$4->sz;

			temp->setVariableType($3->getType());

			n=max(1,temp->sz);
			temp->allocateMemory($3->getType(),n);
			params.push_back(temp);
			//--------------------------------------------------------------------
		}
		| parameter_list COMMA type_specifier
		{
			fprintf(logout,"line no. %d: parameter_list : parameter_list COMMA type_specifier\n",line);

			$$->edge.push_back(new SymbolInfo("",$3->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("param");

			for(int i=0;i<$$->edge.size();i++){
				fprintf(logout,"%s %s",$$->edge[i]->getType().c_str(),$$->edge[i]->getName().c_str());
				if(i<$$->edge.size()-1)
					fprintf(logout,",");
			}

			fprintf(logout,"\n\n");
		}
 		| type_specifier ID
 		{
			fprintf(logout,"line no. %d: parameter_list : type_specifier ID\n",line);

			SymbolInfo *x=new SymbolInfo("parameter_list");
			$$=x;

			//edge is the list or parameters where each parameter has id-name and type
			$$->edge.push_back(new SymbolInfo($2->getName(),$1->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("param");

			fprintf(logout,"%s %s\n\n",$1->getType().c_str(),$2->getName().c_str());

			//--------------------------------------------------------------------
			//insert in the current scope, already a new scope has been created
			//we insert in params for now, later we will insert them in the table
			SymbolInfo *temp=new SymbolInfo($2->getName(),"ID");

			int n;
			temp->sz=$2->sz;

			temp->setVariableType($1->getType());
			
			n=max(1,temp->sz);
			temp->allocateMemory($1->getType(),n);
			params.push_back(temp);
			//--------------------------------------------------------------------
		}
		| type_specifier
		{
			fprintf(logout,"line no. %d: parameter_list : type_specifier\n",line);
			SymbolInfo *x=new SymbolInfo("parameter_list");
			$$=x;

			//edge is the list or parameters where each parameter has id-name and type
			$$->edge.push_back(new SymbolInfo("",$1->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("param");

			fprintf(logout,"%s\n\n",$1->getType().c_str());
		}
 		;

 		
compound_statement : LCURL statements RCURL
		{
			fprintf(logout,"line no. %d: compound_statement : LCURL statements RCURL\n",line);
			fprintf(logout,"{\n");codes="{";
			
			for(int i=0;i<$2->edge.size();i++){
				codes+=$2->edge[i]->getName()+"\n" ;
				fprintf(logout,"%s\n",$2->edge[i]->getName().c_str());
			}

			fprintf(logout,"}\n\n");codes+="}\n";

			SymbolInfo *newSymbol=new SymbolInfo(codes,"compound_statement");
			$$=newSymbol;
		}
 		    | LCURL RCURL
 		{
			fprintf(logout,"line no. %d: compound_statement : LCURL RCURL\n",line);
			fprintf(logout,"{}");

			SymbolInfo *newSymbol=new SymbolInfo("{}","compound_statement");
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
			variable_type = "int";

			SymbolInfo *newSymbol = new SymbolInfo("int");
			$$ = newSymbol;
			fprintf(logout,"%s\n\n",$$->getType().c_str());
		}
 		| FLOAT
 		{
			fprintf(logout,"line no. %d: type_specifier : FLOAT\n",line);
			variable_type="float";

			SymbolInfo *newSymbol = new SymbolInfo("float");
			$$ = newSymbol;
			fprintf(logout,"%s\n\n",$$->getType().c_str());
		}
 		| VOID
 		{
			fprintf(logout,"line no. %d: type_specifier : VOID\n",line);
			variable_type="void";

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
 			if(variable_type=="void") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else {
 				//insert in SymbolTable directly if not declared before
 				if(!table.Insert($3->getName(),"ID",logout)) {
 					fprintf(error,"semantic error found at line %d: variable \'%s\' declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

				else {
 					SymbolInfo *temp=table.lookUp($3->getName());
 					temp->setVariableType(variable_type);
 					temp->allocateMemory(variable_type,1);
 					temp->setIdentity("var");
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
 			if(variable_type=="void") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else {
 				//insert in SymbolTable directly if not declared before
 				if(!table.Insert($3->getName(),"ID",logout)) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					SymbolInfo *x=table.lookUp($3->getName());
 					x=table.lookUp($3->getName());
 					x->setVariableType(variable_type);

 					int n=atoi($5->getName().c_str());
 					x->allocateMemory(variable_type,n);
 					x->sz=n;
 					x->setIdentity("arr");
 				}
 			}
 			//---------------------------------------------------------------------------

 		}
 		  | ID
 		{
 			fprintf(logout,"line no. %d: declaration_list : ID\n",line);
 			fprintf(logout,"%s\n\n",$1->getName().c_str());

 			SymbolInfo *newSymbol = new SymbolInfo("declaration_list");
 			$$ = newSymbol;
 			$$->edge.push_back($1);

 			//---------------------------------------------------------------------------
			//semantics and insertion in the table
 			if(variable_type=="void") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else {
 				//insert in SymbolTable directly if not declared before
 				if(!table.Insert($1->getName(),"ID",logout)) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					SymbolInfo *temp=table.lookUp($1->getName());
 					temp->setVariableType(variable_type);
 					temp->allocateMemory(variable_type,1);
 					temp->setIdentity("var");
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
 			if(variable_type=="void") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else {
 				//insert in SymbolTable directly if not declared before
 				if(!table.Insert($1->getName(),"ID",logout)) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					SymbolInfo *x=table.lookUp($1->getName());
 					x=table.lookUp($1->getName());
 					x->setVariableType(variable_type);

 					int n=atoi($3->getName().c_str());
 					x->allocateMemory(variable_type,n);
 					x->sz=n;
 					x->setIdentity("arr");
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
			fprintf(logout,"line no. %d: statement : expression_statement\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"statement");
			$$=newSymbol;
		}
	  | compound_statement
	  	{
			fprintf(logout,"line no. %d: statement : compound_statement\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"statement");
			$$=newSymbol;
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  	{
			fprintf(logout,"line no. %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n",line);
			
			codes="for(";codes+=($3->getName()+$4->getName()+$5->getName());
			codes+=")";codes+=$7->getName();

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  	{
			fprintf(logout,"line no. %d: statement : IF LPAREN expression RPAREN statement\n\n",line);
			
			codes="if(";codes+=$3->getName();
			codes+=")";codes+=$5->getName();
			
			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
	  	{
			fprintf(logout,"line no. %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n\n",line);
			
			codes+="if(";codes+=$3->getName();
			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | WHILE LPAREN expression RPAREN statement
		{
			fprintf(logout,"line no. %d: statement : WHILE LPAREN expression RPAREN statement\n",line);
			
			codes="while(";codes+=$3->getName();
			codes+=")";codes+=$5->getName();

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  	{
			fprintf(logout,"line no. %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n",line);
		}
	  | RETURN expression SEMICOLON
	    {
			fprintf(logout,"line no. %d: statement : RETURN expression SEMICOLON\n",line);
			
			codes="return ";
			codes+=$2->getName();
			codes+=";";

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;

			isReturning=true;
		}
	  ;
	  
expression_statement : SEMICOLON
		{
			fprintf(logout,"line no. %d: expression_statement : SEMICOLON\n",line);
			fprintf(logout,";\n\n");

			$$=$1;
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
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			$$=$1;
		} 		
	 | ID LTHIRD expression RTHIRD 
		{
			fprintf(logout,"line no. %d: variable : ID LTHIRD expression RTHIRD\n",line);
			fprintf(logout,"%s[%s]\n\n",$1->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"["+$3->getName()+"]","variable");
			$$=newSymbol;
			$$->setVariableType($3->getVariableType());

			//--------------------------------------------------------------------------
			//type checking, expression must be int
			if($3->getVariableType()!="int"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: type mismatch, array index must be integer\n\n",line);
			}
			//--------------------------------------------------------------------------
		}
	 ;
	 
 expression : logic_expression
		{
			fprintf(logout,"line no. %d: expression : logic_expression\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			$$=$1;
		}	
	   | variable ASSIGNOP logic_expression 	
		{
			fprintf(logout,"line no. %d: expression : variable ASSIGNOP logic_expression\n",line);
			fprintf(logout,"%s=%s\n\n",$1->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"="+$3->getName(),"expression");
			$$=newSymbol;

			//result of logic_expression must be integers
			$$->setVariableType("int");
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
			fprintf(logout,"line no. %d: rel_expression : simple_expression\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			$$=$1;
		}
		| simple_expression RELOP simple_expression	
		{
			fprintf(logout,"line no. %d: rel_expression : simple_expression RELOP simple_expression\n",line);
			fprintf(logout,"%s%s%s\n\n",$1->getName().c_str(),$2->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"rel_expression");
			$$=newSymbol;
		}
		;
				
simple_expression : term
		{
			fprintf(logout,"line no. %d: simple_expression : term\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			$$=$1;
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

			$$=$1;
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
			fprintf(logout,"line no. %d: unary_expression : factor\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());

			$$=$1;
		}
		 ;
	
factor : variable
		{
			fprintf(logout,"line no. %d: factor : variable\n",line);
			fprintf(logout,"%s\n\n",$$->getName().c_str());
			$$=$1;
		} 
	| ID LPAREN argument_list RPAREN
		{
			fprintf(logout,"line no. %d: factor : ID LPAREN argument_list RPAREN\n",line);
			fprintf(logout,"%s(%s)\n\n",$1->getName().c_str(),$3->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"("+$3->getName()+")","factor");
			$$=newSymbol;
		}
	| LPAREN expression RPAREN
		{
			fprintf(logout,"line no. %d: factor : LPAREN expression RPAREN\n",line);
			fprintf(logout,"(%s)\n\n",$2->getName().c_str());
			
			SymbolInfo *newSymbol=new SymbolInfo("("+$2->getName()+")","factor");
			$$=newSymbol;
		}
	| CONST_INT
		{
			fprintf(logout,"line no. %d: factor : CONST_INT\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());
			$$=$1;

			$$->setVariableType("int");
		} 
	| CONST_FLOAT
		{
			fprintf(logout,"line no. %d: factor : CONST_FLOAT\n",line);
			fprintf(logout,"%s\n\n",$1->getName().c_str());
			$$=$1;

			$$->setVariableType("float");
		}
	| variable INCOP
		{
			fprintf(logout,"line no. %d: factor	: variable INCOP\n",line);
			fprintf(logout,"%s++\n\n",$1->getName().c_str());

			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"++","factor");
			$$=newSymbol;
		} 
	| variable DECOP
		{
			fprintf(logout,"line no. %d: factor	: variable DECOP\n",line);
			fprintf(logout,"%s--\n\n",$1->getName().c_str());

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
	|{}
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
	
	isReturning=false;
	currentFunction=0;
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

