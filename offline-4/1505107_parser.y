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
string codes, assemblyCodes;
string returnType_curr;
string isReturningType;

extern FILE *yyin;
FILE *error,*asmCode,*optimized_asmCode;

SymbolTable table(10);
SymbolInfo *currentFunction;

vector<string> code_list;
vector<string> statement_list;

vector<SymbolInfo*> params;
vector<SymbolInfo*> var_list;
vector<SymbolInfo*> arg_list;

bool isReturning;

void yyerror(const char *s)
{
	cnt_err++;
	fprintf(error,"syntax error \"%s\" Found on Line %d (Error no.%d)\n",s,line,cnt_err);
}


string stoi(int n)
{
	string temp;
	while(n){
		int r=n%10;
		n/=10;
		temp.push_back(r+48);
	}

	reverse(temp.begin(),temp.end());
	return temp;
}

void fillScopeWithParams()
{	
	for(int i=0;i<params.size();i++)
	{
		if(!table.Insert(params[i]->getName(),"ID",logout)){
			semanticErr++;
			fprintf(error,"semantic error found on line %d: variable '%s' already declared before\n\n",line,params[i]->getName().c_str());
		}

		else{
			SymbolInfo *temp=table.lookUp(params[i]->getName());
			temp->setVariableType(params[i]->getVariableType());
			temp->sz=params[i]->sz;
		}
	}

	params.clear();
}


int labelCount=0, tempCount=0; 
string newLabel()
{
	string temp="L"+stoi(labelCount);
	labelCount++;
	return temp;
}

string newTemp()
{
	string temp="T"+stoi(tempCount);
	tempCount++;
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

%type<symbol>compound_statement type_specifier parameter_list declaration_list var_declaration unit func_declaration statement statements variable expression factor arguments argument_list expression_statement unary_expression simple_expression logic_expression rel_expression term func_definition
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%define parse.error verbose

%%

start : program {
		 	$$=$1;

		 	if(!semanticErr && !cnt_err)
		 	{
		 		//init
		 		string init=".MODEL SMALL\nSTACK 100H\n";
		 		
		 		init+=".DATA\n";
		 		
		 		//variables

		 		init+=".CODE\n";

		 		//function for PRINTLN
		 		init+="PRINT_ID PROC\n\n";
		 		init+="\t;SAVE IN STACK\n";
		 		init+="\tPUSH AX\n";
		 		init+="\tPUSH BX\n";
		 		init+="\tPUSH CX\n";
		 		init+="\tPUSH DX\n\n";
		 		init+="\t;CHECK IF NEGATIVE\n";
		 		init+="\tOR AX, AX\n";
		 		init+="\tJGE PRINT_NUMBER\n\n";
		 		init+="\t;PRINT MINUS SIGN\n";
		 		init+="\tPUSH AX\n";
		 		init+="\tMOV AH, 2\n";
		 		init+="\tMOV DL, '-'\n";
		 		init+="\tINT 21H\n";
		 		init+="\tPOP AX\n\n";
		 		init+="\tNEG AX\n\n";
		 		init+="\tPRINT_NUMBER:\n";
		 		init+="\tXOR CX, CX\n";
		 		init+="\tMOV BX, 10D\n\n";
		 		init+="\tREPEAT:\n\n";
		 		init+="\t\t;AX:DX- QUOTIENT:REMAINDER\n";
		 		init+="\t\tXOR DX, DX\n";
		 		init+="\t\tDIV BX  ;DIVIDE BY 10\n";
		 		init+="\t\tPUSH DX ;PUSH THE REMAINDER IN STACK\n\n";
		 		init+="\t\tINC CX\n\n";
		 		init+="\t\tOR AX, AX\n";
		 		init+="\t\tJNE REPEAT\n\n";

		 		init+="\tMOV AH, 2\n\n";
		 		init+="\tPRINT_LOOP:\n";
		 		init+="\t\tPOP DX\n";
		 		init+="\t\tADD DL, 30H\n";
		 		init+="\t\tINT 21H\n";
		 		init+="\t\tLOOP tPRINT_LOOP\n";

		 		init+="\tPOP AX\n";
		 		init+="\tPOP BX\n";
		 		init+="\tPOP CX\n";
		 		init+="\tPOP DX\n\n";
		 		init+="\tRET\n";
		 		init+="PRINT_ID ENDP\n\n";

		 		fprintf(asmCode,"%s",init.c_str());
		 	}
		}
	;

program : program unit {
			$$=$1;
			$$->code+=$2->code;
		} 
	| unit {
			$$=$1;
		}
	;
	
unit : var_declaration {
		   	$$=$1;
   	   	}
     | func_declaration {
		   	$$=$1;
   	   	}
     | func_definition {
		   	$$=$1;
   	   	}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			//int foo(int a,float b);
			if(!table.Insert($2->getName(),"ID",logout)){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: re-declaration of function \'%s\'\n\n",line,$2->getName().c_str());
			}

			else{
				SymbolInfo *x=table.lookUp($2->getName());
				x->setReturnType($1->getType());
				x->setIdentity("function_declaration");

				for(int i=0;i<$4->edge.size();i++){
					x->edge.push_back($4->edge[i]);
				}
			}

			codes="";
			codes+=($1->getType()+" "+$2->getName()+"(");
			for(int i=0;i<$4->edge.size();i++){
				codes+=($4->edge[i]->getType()+" "+$4->edge[i]->getName());
				if(i<$4->edge.size()-1)
					codes+=",";
			}
			codes+=");";

			fprintf(logout,"%s\n\n",codes.c_str());
			
			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_declaration");
			$$=newSymbol;

			params.clear();
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

			SymbolInfo *newSymbol=new SymbolInfo(codes,"func_declaration");
			$$=newSymbol;
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN{table.EnterScope(logout);fillScopeWithParams();} compound_statement
		{
			codes=$1->getType()+" ";
			codes+=$2->getName(); codes+="(";
			for(int i=0;i<$4->edge.size();i++){
				codes+=$4->edge[i]->getType()+" "+$4->edge[i]->getName();
			}

			codes+=")";
			codes+=$7->getName();

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

			else{
				//check if function is returning the right type of variable
				if(isReturningType!=$1->getType()){
					semanticErr++;
					fprintf(logout,"semantic error found in line %d: return type didn't match\n\n",line);
				}
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

						if(f)
						{
							//match return type
							if(x->getReturnType()==$1->getType()){
								//already inserted and parameters matched, edit it
								x->setIdentity("func_defined");
								currentFunction=x;

								for(int i=0;i<var_list.size();i++){
									x->edge.push_back(var_list[i]);
									//cout<<"in func "<<var_list[i]->getIdentity()<<endl;
								}

								x->setReturnType($1->getType());
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
				x->setReturnType($1->getType());
				
				for(int i=0;i<var_list.size();i++){
					x->edge.push_back(var_list[i]);
				}

				currentFunction=x;cout<<var_list.size()<<" "<<$2->getName()<<endl;
			}

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

			var_list.clear();
		}
 		;				


parameter_list : parameter_list COMMA type_specifier ID
		{
			$$->edge.push_back(new SymbolInfo($4->getName(),$3->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("var");

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
			$$->edge.push_back(new SymbolInfo("",$3->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("param");
		}
 		| type_specifier ID
 		{
			SymbolInfo *x=new SymbolInfo("parameter_list");
			$$=x;

			//edge is the list or parameters where each parameter has id-name and type
			$$->edge.push_back(new SymbolInfo($2->getName(),$1->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("var");

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
			SymbolInfo *x=new SymbolInfo("parameter_list");
			$$=x;

			//edge is the list or parameters where each parameter has id-name and type
			$$->edge.push_back(new SymbolInfo("",$1->getType()));
			$$->edge[$$->edge.size()-1]->setIdentity("param");
		}
 		;

 		
compound_statement : LCURL statements RCURL
		{
			for(int i=0;i<$2->edge.size();i++){
				codes+=$2->edge[i]->getName()+"\n" ;
			}

			SymbolInfo *newSymbol=new SymbolInfo(codes,"compound_statement");
			$$=newSymbol;
		}
 		    | LCURL RCURL
 		{
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
			variable_type = "int";

			SymbolInfo *newSymbol = new SymbolInfo("int");
			$$ = newSymbol;
		}
 		| FLOAT
 		{
			variable_type="float";

			SymbolInfo *newSymbol = new SymbolInfo("float");
			$$ = newSymbol;
		}
 		| VOID
 		{
			variable_type="void";

			SymbolInfo *newSymbol = new SymbolInfo("void");
			$$ = newSymbol;
		}
 		;
 		
declaration_list : declaration_list COMMA ID
		{
			$3->setIdentity("var");
			$3->setVariableType(variable_type);
			
			$$->edge.push_back($3);
			
			//---------------------------------------------------------------------------
			//semantics and insertion in the table
 			if(variable_type=="void") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else
 			{
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
			$3->setIdentity("arr");
			$3->setVariableType(variable_type);

			$$->edge.push_back($3);
 			

			//---------------------------------------------------------------------------
			//semantics and insertion in the table
 			if(variable_type=="void") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else 
 			{
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
 			SymbolInfo *newSymbol = new SymbolInfo("declaration_list");
 			$$ = newSymbol;

 			$1->setVariableType(variable_type);$1->setIdentity("var");

 			$$->setIdentity("declaration_list");
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
 			SymbolInfo *x = new SymbolInfo("declaration_list");
 			$$ = x;$$->setIdentity("declaration_list");

 			$1->sz=atoi($3->getName().c_str());$1->setVariableType(variable_type);
 			$1->setIdentity("arr");

 			$$->edge.push_back($1);

 			//---------------------------------------------------------------------------
			//semantics and insertion in the table
 			if(variable_type=="void") {
 				fprintf(error,"semantic error found at line %d: variable cannot be of type void\n\n",line);
 				semanticErr++;
 			}

 			else 
 			{
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
			SymbolInfo *newSymbol=new SymbolInfo("statements","statements");
			newSymbol->edge.push_back($1);
			$$=newSymbol;
		}
	   | statements statement
	    {
			$1->edge.push_back($2);
			$$=$1;
		}
	   ;
	   
statement : var_declaration
		{
			$$=$1;
		}
	  | expression_statement
	  	{
			$$=$1;
		}
	  | compound_statement
	  	{
			$$=$1;
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  	{
			codes="for(";codes+=($3->getName()+$4->getName()+$5->getName());
			codes+=")";codes+=$7->getName();

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  	{
			codes="if(";codes+=$3->getName();
			codes+=")";codes+=$5->getName();
			
			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
	  	{
			codes="if(";codes+=$3->getName();
			codes+=")";codes+=$5->getName();codes+="else";codes+=$7->getName();
			
			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | WHILE LPAREN expression RPAREN statement
		{
			codes="while(";codes+=$3->getName();
			codes+=")";codes+=$5->getName();

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  	{
	  		SymbolInfo *temp=new SymbolInfo("println","statement");
	  		$$=temp;
	  		
			assemblyCodes="MOV AX, "+$3->getName();
			assemblyCodes+=("\tCALL PRINT_ID\n");
		}
	  | RETURN expression SEMICOLON
	    {
			codes="return ";
			codes+=$2->getName();
			codes+=";";

			fprintf(logout,"%s\n\n",codes.c_str());

			SymbolInfo *newSymbol=new SymbolInfo(codes,"statement");
			$$=newSymbol;

			isReturning=true;
			isReturningType=$2->getVariableType();
		}
	  ;
	  
expression_statement : SEMICOLON
		{
			SymbolInfo *newSymbol=new SymbolInfo(";","expression_statement");
			$$=newSymbol;
		}			
			| expression SEMICOLON
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+";","expression_statement");
			$$=newSymbol;
			$$->setVariableType($1->getVariableType());
		} 
			;
	  
variable : ID
		{
			$$=$1;
			$$->setIdentity("var");

			//--------------------------------------------------
			//#semantic: see if variable has been declared
			SymbolInfo *x=table.lookUp($1->getName());
			if(!x){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable '%s' not declared in this scope\n\n",line,$1->getName().c_str());
			}

			else{
				$$->setVariableType(x->getVariableType());
			}
			//--------------------------------------------------
		} 		
	 | ID LTHIRD expression RTHIRD 
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName(),"variable");
			$$=newSymbol;
			$$->setVariableType($3->getVariableType());
			$$->setIdentity("arr");
			$$->sz=atoi($3->getName().c_str());

			//--------------------------------------------------------------------------
			//#semantic: type checking, expression must be int, e.g: a[5.6]
			if($3->getVariableType()!="int"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: type mismatch, array index must be integer\n\n",line);
			}
			//--------------------------------------------------------------------------

			//--------------------------------------------------
			//#semantic: see if variable has been declared
			SymbolInfo *x=table.lookUp($1->getName());
			if(!x){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable '%s' not declared in this scope\n\n",line,$1->getName().c_str());
			}

			else{
				$$->setVariableType(x->getVariableType());
			}
			//--------------------------------------------------
		}
	 ;
	 
 expression : logic_expression
		{
			$$=$1;
		}	
	   | variable ASSIGNOP logic_expression 	
		{
			codes=$1->getName();
			if($1->sz)
				codes+="["+stoi($1->sz)+"]";

			SymbolInfo *newSymbol=new SymbolInfo(codes+"="+$3->getName(),"expression");
			$$=newSymbol;

			codes="";

			//---------------------------------------------------------------------------
			//#semantic: Array Index: You have to check whether there is index used with array and vice versa.
			//e.g: int a[10];a=8; or int a;a[5]=5;
			SymbolInfo *x=table.lookUp($1->getName());
			if(x)
			{	
				//type of var
				$$->setVariableType(x->getVariableType());

				if(x->getIdentity()=="arr" && $1->getIdentity()!="arr"){
					semanticErr++;
					fprintf(error,"semantic error found in line %d: array index error\n\n",line);
				}

				else if(x->getIdentity()!="arr" && $1->sz>0){
					semanticErr++;
					fprintf(error,"semantic error found in line %d: array index error\n\n",line);
				}
			}

			else{
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable '%s' not declared in this scope\n\n",line,$1->getName().c_str());
			}
			//---------------------------------------------------------------------------
			//#semantic: check if float is assigned to int or vice-versa
			if(x)
			{
				if(x->getVariableType()!=$3->getVariableType()){
					semanticErr++;
					fprintf(error,"semantic error found in line %d: type mismatch in assignment \n\n",line,$3->getVariableType().c_str(),x->getVariableType().c_str());
				}
			}
			//---------------------------------------------------------------------------
			//#semantic: expression cannot have void return type functions called
			if(returnType_curr=="void"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: void type function can't be part of expression\n\n",line);
				returnType_curr="none";
			}
			//---------------------------------------------------------------------------
		}
	   ;
			
logic_expression : rel_expression
		{
			$$=$1;
		} 	
		 | rel_expression LOGICOP rel_expression 	
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"logic_expression");
			$$=newSymbol;

			//------------------------------------------------------------------
			//#semantic: LOGICOP MUST BE INT
			$$->setVariableType("int");

			//#semantic: both sides of RELOP should be integer
			if($1->getVariableType()!="int" || $3->getVariableType()!="int"){
				semanticErr++;
				fprintf(error,"semantic error in line %d found: both operands of %s should be integers\n\n",line,$2->getName().c_str());
			}
			//------------------------------------------------------------------
		}
		 ;
			
rel_expression : simple_expression 
		{
			$$=$1;
		}
		| simple_expression RELOP simple_expression	
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"rel_expression");
			$$=newSymbol;

			//------------------------------------------------------------------
			//#semantic: RELOP MUST BE INT
			$$->setVariableType("int");

			//#semantic: both sides of RELOP should be integer
			if($1->getVariableType()!="int" || $3->getVariableType()!="int"){
				semanticErr++;
				fprintf(error,"semantic error in line %d found: both operands of %s should be integers\n\n",line,$2->getName().c_str());
			}
			//------------------------------------------------------------------
		}
		;
				
simple_expression : term
		{
			$$=$1;
		} 
		  | simple_expression ADDOP term
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"simple_expression");
			$$=newSymbol;

			if($1->getVariableType()=="float" || $3->getVariableType()=="float")
				$$->setVariableType("float");
			else
				$$->setVariableType("int");
		} 
		  ;
					
term :	unary_expression
		{
			$$=$1;
		}
     |  term MULOP unary_expression
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName()+$3->getName(),"term");
			$$=newSymbol;

			//------------------------------------------------------------------------
			//#semantic: check 5%2.5
			if($2->getName()=="%" && ($1->getVariableType()!="int" || $3->getVariableType()!="int")){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: type mismatch, mod operation is only possible with integer operands\n\n",line);
			}
			//------------------------------------------------------------------------

			//set variable_type
			if($2->getName()=="%")
				$$->setVariableType("int");
			else
			{
				if($1->getVariableType()=="float" || $3->getVariableType()=="float")
					$$->setVariableType("float");
				else
					$$->setVariableType("int");
			}
		}
     ;

unary_expression : ADDOP unary_expression
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+$2->getName(),"unary_expression");
			$$=newSymbol;
			$$->setVariableType($2->getVariableType());
		}  
		 | NOT unary_expression 
		{
			$$=$2;
		}
		 | factor 
		{
			$$=$1;
		}
		 ;
	
factor : variable
		{
			$$=$1;
		} 
	| ID LPAREN argument_list RPAREN
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+"("+$3->getName()+")","factor");
			$$=newSymbol;

			//--------------------------------------------------------------------------
			//#semantic: calling functions, check the arguments
			SymbolInfo *func=table.lookUp($1->getName());

			//set the variable type of factor and also current return type
			if(func) 
				$$->setVariableType(func->getReturnType()), returnType_curr=func->getReturnType();
			else
				$$->setVariableType("func_not_found");

			if(func && func->getIdentity()=="func_defined"){
				if(func->edge.size()!=arg_list.size()){
					semanticErr++;
					fprintf(error,"semantic error found in line %d: argument list didn't match, wrong number of arguments\n\n",line);
				}

				else
				{
					for(int i=0;i<func->edge.size();i++)
					{
						SymbolInfo *x=table.lookUp(arg_list[i]->getName());
						if(x)
						{
							if(x->getVariableType()!=func->edge[i]->getVariableType() || x->sz!=func->edge[i]->sz){
								semanticErr++;
								fprintf(error,"semantic error found in line %d: type mismatch, wrong type of argument given\n\n",line);
								break;
							}
						}

						//parameter can be CONST_INT or CONST_FLOAT 
						else if(arg_list[i]->getIdentity()=="var"){
							semanticErr++;
							fprintf(error,"semantic error found in line %d: variable '%s' not found\n\n",line,arg_list[i]->getName().c_str());
							break;
						}
					}
				}
			}

			else{
				semanticErr++;
				fprintf(error,"semantic error found in line %d: function named '%s' not defined\n\n",line,$1->getName().c_str());
			}
			//--------------------------------------------------------------------------

			arg_list.clear();
		}
	| LPAREN expression RPAREN
		{
			$$=$2;
		}
	| CONST_INT
		{
			$$=$1;
			$$->setVariableType("int");
		} 
	| CONST_FLOAT
		{
			$$=$1;
			$$->setVariableType("float");
		}
	| variable INCOP
		{
			//#semantic error check
			SymbolInfo *temp=table.lookUp($1->getName());
			if(!temp){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable %s not declared in this scope\n\n",line,$1-?getName().c_str());
			}

			$$=$1;
			assemblyCodes=$$->getCode();
			
			assemblyCodes+=("\tmov ax, "+$1->getName()+"\n");
			assemblyCodes+=("\tadd ax, 1\n");
			assemblyCodes+=("\tmov "+$1->getName()+", ax\n");
			
			$$->setCode(assemblyCodes);
		} 
	| variable DECOP
		{
			//#semantic error check
			SymbolInfo *temp=table.lookUp($1->getName());
			if(!temp){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable %s not declared in this scope\n\n",line,$1-?getName().c_str());
			}

			$$=$1;
			assemblyCodes=$$->getCode();
			
			assemblyCodes+=("\tmov ax, "+$1->getName()+"\n");
			assemblyCodes+=("\tsub ax, 1\n");
			assemblyCodes+=("\tmov "+$1->getName()+", ax\n");
			
			$$->setCode(assemblyCodes);
;		}
	;
	
argument_list : arguments
		{
			$$=$1;
			$$->setType("argument_list");
		}
	|{
		SymbolInfo *newSymbol=new SymbolInfo("","argument_list");
		$$=newSymbol;
	 }
			  ;
	
arguments : arguments COMMA logic_expression
		{
			SymbolInfo *newSymbol=new SymbolInfo($1->getName()+","+$3->getName(),"arguments");
			$$=newSymbol;

			arg_list.push_back($3);
		}
	      | logic_expression
	    {
			$$=$1;
			arg_list.push_back($$);
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

	error=fopen(argv[2],"w");
	fclose(error);

	asmCode=fopen(argv[3],"w");
	fclose(asmCode);

	optimized_asmCode=fopen(argv[4],"w");
	fclose(optimized_asmCode);
	
	error=fopen(argv[2],"a");
	asmCode=fopen(argv[3],"a");
	optimized_asmCode=fopen(argv[4],"a");
	
	isReturning=false; currentFunction=0;
	cnt_err=0; returnType_curr="none";

	yyparse();

	//print the SymbolTable and other credentials
	fprintf(error,"total lines read: %d\n",line-1);
	fprintf(error,"total errors encountered: %d",cnt_err+semanticErr);
	
	fclose(error);
	fclose(asmCode);
	fclose(optimized_asmCode);
	
	return 0;
}

