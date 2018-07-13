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

vector<string> statement_list;

vector<SymbolInfo*> params;
vector<SymbolInfo*> var_list;
vector<SymbolInfo*> arg_list;
vector<pair<string,string>> variableListForInit;

bool isReturning;

void yyerror(const char *s)
{
	cnt_err++;
	fprintf(error,"syntax error \"%s\" Found on Line %d (Error no.%d)\n",s,line,cnt_err);
}


string stoi(int n)
{
	string temp;

	if(!n){
		return "0";
	}

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
		if(!table.Insert(params[i]->getName(),"ID")){
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


int labelCount=1, tempCount=1; 
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

	variableListForInit.push_back({temp,"0"});
	return temp;
}

void optimizeCode()
{
    string str;
    map<string,string> reg_and_var;

    while(getline(cin,str))
    {
        //check for MOV x, y
        int i,j,k;

        if(str.find("MOV")!=string::npos)
        {
            //first find end of mov
            k=0;j=-1;
            while(k<str.length())
            {
                if(str[k]=='M' && str[k+1]=='O' && str[k+2]=='V'){
                    j=k+3;
                    break;
                }

                k++;
            }

            //now from j till end split the string
            string x,y;

            k=1;
            for(i=j;i<str.length();i++)
            {
                if(str[i]==',')
                    k=2;

                else if(str[i]!=' '){
                    if(k==1)
                        x.push_back(str[i]);
                    else
                        y.push_back(str[i]);
                }
            }

            //MOV x,y
            //now we optimize
            if(x=="AH" && (y=="1" || y=="2"))
                fprintf(optimized_asmCode,"%s\n",str.c_str());

            else{
                 if(reg_and_var[x]!=y && x!=reg_and_var[y])
                {
                    reg_and_var[x]=y;
                    fprintf(optimized_asmCode,"%s\n",str.c_str());
                }
            }
        }

        else
            fprintf(optimized_asmCode,"%s\n",str.c_str());
    }
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

%type<symbol>start program compound_statement type_specifier parameter_list declaration_list var_declaration unit func_declaration statement statements variable expression factor arguments argument_list expression_statement unary_expression simple_expression logic_expression rel_expression term func_definition
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%define parse.error verbose

%%

start : program {
		 	$$=$1;

		 	if(!semanticErr && !cnt_err)
		 	{
		 		//init
		 		string init=".MODEL SMALL\n.STACK 100H\n";
		 		
		 		init+=".DATA\n";
		 		
		 		//variables
		 		for(int i=0;i<variableListForInit.size();i++){
		 			if(variableListForInit[i].second=="0")
		 				init+=("\t"+variableListForInit[i].first+" DW ?\n");
		 			else
		 				init+=("\t"+variableListForInit[i].first+" DW "+variableListForInit[i].second+" DUP(?)\n");
		 		}

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
		 		init+="\tREPEAT_CALC:\n\n";
		 		init+="\t\t;AX:DX- QUOTIENT:REMAINDER\n";
		 		init+="\t\tXOR DX, DX\n";
		 		init+="\t\tDIV BX  ;DIVIDE BY 10\n";
		 		init+="\t\tPUSH DX ;PUSH THE REMAINDER IN STACK\n\n";
		 		init+="\t\tINC CX\n\n";
		 		init+="\t\tOR AX, AX\n";
		 		init+="\t\tJNZ REPEAT_CALC\n\n";

		 		init+="\tMOV AH, 2\n\n";
		 		init+="\tPRINT_LOOP:\n";
		 		init+="\t\tPOP DX\n";
		 		init+="\t\tADD DL, 30H\n";
		 		init+="\t\tINT 21H\n";
		 		init+="\t\tLOOP PRINT_LOOP\n";

		 		init+="\n\t;NEWLINE\n";
		 		init+="\tMOV AH, 2\n";
		 		init+="\tMOV DL, 0AH\n";
		 		init+="\tINT 21H\n";
		 		init+="\tMOV DL, 0DH\n";
		 		init+="\tINT 21H\n\n";

		 		init+="\tPOP AX\n";
		 		init+="\tPOP BX\n";
		 		init+="\tPOP CX\n";
		 		init+="\tPOP DX\n\n";
		 		init+="\tRET\n";
		 		init+="PRINT_ID ENDP\n\n";

		 		fprintf(asmCode,"%s",init.c_str());
		 		fprintf(asmCode,"%s",$$->getCode().c_str());

		 		optimizeCode();
		 	}
		}
	;

program : program unit {
			$$=$1;
			$$->setCode($$->getCode()+$2->getCode());
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
			if(!table.Insert($2->getName(),"ID")){
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
			
			SymbolInfo *newSymbol=new SymbolInfo("function - "+$2->getName(),"func_declaration");
			$$=newSymbol;

			params.clear();
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			//int foo();
			if(!table.Insert($2->getName(),"ID")){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: redeclaration of function \'%s\'\n\n",line,$2->getName().c_str());	
			}

			else{
				SymbolInfo *x=table.lookUp($2->getName());
				x->setReturnType($1->getType());
				x->setIdentity("function_declaration");
			}
			
		
			SymbolInfo *newSymbol=new SymbolInfo("function - "+$2->getName(),"func_declaration");
			$$=newSymbol;
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN{table.EnterScope();fillScopeWithParams();} compound_statement
		{
			//-------------------------------------------------------------------------
			//assembly code generation
			if($2->getName()=="main")
				assemblyCodes="MAIN PROC\n\n";
			else
				assemblyCodes=$2->getName()+" PROC\n\n";

			//if main function then initialize data segment
			if($2->getName()=="main"){
				assemblyCodes+="\t;INITIALIZE DATA SEGMENT\n";
				assemblyCodes+="\tMOV AX, @DATA\n";
				assemblyCodes+="\tMOV DS, AX\n\n";
			}

			//function body
			assemblyCodes+=$7->getCode();

			//ending of function
			if($2->getName()=="main") {
				assemblyCodes+="\n\tMOV AX, 4CH\n\tINT 21H";
				assemblyCodes+=("\nMAIN ENDP\n\nEND MAIN");
			}

			else{
				assemblyCodes+="RET\n";
				assemblyCodes+=$2->getName()+" ENDP\n\n";
			}
				
			//-------------------------------------------------------------------------
			

			SymbolInfo *newSymbol=new SymbolInfo("function - "+$2->getName(),"func_definition");
			$$=newSymbol;
			$$->setCode(assemblyCodes);

			//------------------------------------------
			//current scope obtained, insert the function in the global scope
			int id=table.getCurrentID();
			var_list=table.printCurrentAndGetAll();
			table.ExitScope();
			//------------------------------------------

			//-----------------------------------------------------------------------
			//semantic error: type_specifier void and return
			if(isReturning && $1->getType()=="void"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: type-specifier is of type void, can't return\n\n",line);
			}

			else{
				//check if function is returning the right type of variable
				if(isReturningType!=$1->getType()){
					semanticErr++;
					fprintf(error,"semantic error found in line %d: return type didn't match\n\n",line);
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
				table.Insert($2->getName(),"ID");
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
		| type_specifier ID LPAREN RPAREN{table.EnterScope();} compound_statement
		{
			
			//-------------------------------------------------------------------------
			//assembly code generation
			if($2->getName()=="main")
				assemblyCodes="MAIN PROC\n\n";
			else
				assemblyCodes=$2->getName()+" PROC\n\n";

			//if main function then initialize data segment
			if($2->getName()=="main"){
				assemblyCodes+="\t;INITIALIZE DATA SEGMENT\n";
				assemblyCodes+="\tMOV AX, @DATA\n";
				assemblyCodes+="\tMOV DS, AX\n\n";
			}

			//function body
			assemblyCodes+=$6->getCode();

			//ending of function
			if($2->getName()=="main") {
				assemblyCodes+="\n\tMOV AX, 4CH\n\tINT 21H";
				assemblyCodes+=("\nMAIN ENDP\n\nEND MAIN");
			}

			else{
				assemblyCodes+="RET\n";
				assemblyCodes+=$2->getName()+" ENDP\n\n";
			}
			//-------------------------------------------------------------------------
			

			SymbolInfo *newSymbol=new SymbolInfo("function - "+$2->getName(),"func_definition");
			$$=newSymbol;
			$$->setCode(assemblyCodes);

			//------------------------------------------
			//current scope obtained, insert the function in the global scope
			int id=table.getCurrentID();
			var_list=table.printCurrentAndGetAll();
			table.ExitScope();
			//------------------------------------------

			//-----------------------------------------------------------------------
			//semantic error: type_specifier void and return
			if(isReturning && $1->getType()=="void"){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: type-specifier is of type void, can't return\n\n",line);
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
				table.Insert($2->getName(),"ID");
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
			$$=$2;
		}
 		    | LCURL RCURL
 		{
			SymbolInfo *newSymbol=new SymbolInfo("compound_statement","dummy");
			$$=newSymbol;
		}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		{
			codes="";
			codes += ($1->getType()+" ");

			//print the declaration_list
			for(int i=0;i<$2->edge.size();i++){
				codes += $2->edge[i]->getName();
				
				if($2->edge[i]->sz>0)
					codes+="["+stoi($2->edge[i]->sz)+"]";
				
				if(i<$2->edge.size()-1)
					codes+=",";
			}

			codes+="SEMICOLON";

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
			//---------------------------------------------------------------------
			//code generation
 			variableListForInit.push_back({$3->getName()+stoi(table.getCurrentID()),"0"});
 			//---------------------------------------------------------------------

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
 				if(!table.Insert($3->getName(),"ID")) {
 					fprintf(error,"semantic error found at line %d: variable \'%s\' declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

				else {
 					SymbolInfo *temp=table.lookUp($3->getName());
 					temp->setVariableType(variable_type);
 					temp->setIdentity("var");
 				}
 			}
 			//---------------------------------------------------------------------------

		}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		{
 			//---------------------------------------------------------------------
 			//code generation
 			variableListForInit.push_back({$3->getName()+stoi(table.getCurrentID()),$5->getName()});
 			//---------------------------------------------------------------------
 			
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
 				if(!table.Insert($3->getName(),"ID")) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					SymbolInfo *x=table.lookUp($3->getName());
 					x=table.lookUp($3->getName());
 					x->setVariableType(variable_type);

 					int n=atoi($5->getName().c_str());
 					x->sz=n;
 					x->setIdentity("arr");
 				}
 			}
 			//---------------------------------------------------------------------------

 		}
 		  | ID
 		{
 			//---------------------------------------------------------------------
			//code generation
 			variableListForInit.push_back({$1->getName()+stoi(table.getCurrentID()),"0"});
 			//---------------------------------------------------------------------

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
 				if(!table.Insert($1->getName(),"ID")) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					SymbolInfo *temp=table.lookUp($1->getName());
 					temp->setVariableType(variable_type);
 					
 					temp->setIdentity("var");
 				}
 			}
 			//---------------------------------------------------------------------------
 		}
 		  | ID LTHIRD CONST_INT RTHIRD
 		{
 			//---------------------------------------------------------------------
 			//code generation
 			variableListForInit.push_back({$1->getName()+stoi(table.getCurrentID()),$3->getName()});
 			//---------------------------------------------------------------------
 			
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
 				if(!table.Insert($1->getName(),"ID")) {
 					fprintf(error,"semantic error found at line %d: variable %s declared before\n\n",line,$1->getName().c_str());
 					semanticErr++;
 				}

 				else {
 					SymbolInfo *x=table.lookUp($1->getName());
 					x=table.lookUp($1->getName());
 					x->setVariableType(variable_type);

 					int n=atoi($3->getName().c_str());
 					x->sz=n;
 					x->setIdentity("arr");
 				}
 			}
 			//---------------------------------------------------------------------------
 		}
 		  ;
 		  
statements : statement
		{
			$$=$1;
		}
	   | statements statement
	    {
			$$=$1;
			$$->setCode($$->getCode()+$2->getCode());
		}
	   ;
	   
statement : var_declaration {
			$$=$1;
		}
	  | expression_statement {
			$$=$1;
		}
	  | compound_statement {
			$$=$1;
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  	{
			$$=$3;

			string label1=newLabel(), label2=newLabel();
			
			assemblyCodes=$$->getCode();
			assemblyCodes+=(label1+":\n");	//REPEAT
			
			assemblyCodes+=$4->getCode();
			
			assemblyCodes+=("\tMOV AX, "+$4->getName()+"\n");
			assemblyCodes+="\tCMP AX, 0\n";
			assemblyCodes+="\tJE "+label2+"\n";

			assemblyCodes+=$7->getCode();
			assemblyCodes+=$5->getCode();
			assemblyCodes+="\tJMP "+label1+"\n";
			
			assemblyCodes+=("\t"+label2+":\n");

			$$->setCode(assemblyCodes);
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  	{
			$$=$3;
	
			string label=newLabel();
			
			assemblyCodes=$$->getCode();
			assemblyCodes+=("\tMOV AX, "+$3->getName()+"\n");

			assemblyCodes+="\tCMP AX, 0\n";
			assemblyCodes+=("\tJE "+label+"\n");
			assemblyCodes+=$5->getCode();
			assemblyCodes+=("\t"+label+":\n");
					
			$$->setCode(assemblyCodes);		
			$$->setName("statement");$$->setType("if");	//for debugging purpose
		}
	  | IF LPAREN expression RPAREN statement ELSE statement
	  	{
			$$=$3;

			string else_condition=newLabel();
			string after_else=newLabel();

			assemblyCodes=$$->getCode();
			
			assemblyCodes+=("\tMOV AX, "+$3->getName()+"\n");
			assemblyCodes+="\tCMP AX, 0\n";
			assemblyCodes+=("\tJE "+else_condition+"\n");		//false, jump to else
			
			assemblyCodes+=$5->getCode();					//true
			assemblyCodes+=("\tJMP "+after_else);

			assemblyCodes+=("\n\t"+else_condition+":\n");
			assemblyCodes+=$7->getCode();
			assemblyCodes+=("\n\t"+after_else+":\n");

			$$->setCode(assemblyCodes);
			$$->setName("statement");$$->setType("if-else if");
		}
	  | WHILE LPAREN expression RPAREN statement
		{
			$$=new SymbolInfo("while","loop");

			string label1=newLabel(), label2=newLabel();
			
			assemblyCodes=(label1+":\n");	//REPEAT
			
			//check if we can continue executing
			assemblyCodes+=$3->getCode();

			assemblyCodes+=("\tMOV AX, "+$3->getName()+"\n");
			assemblyCodes+="\tCMP AX, 0\n";
			assemblyCodes+="\tJE "+label2+"\n";

			assemblyCodes+=$5->getCode();	//execute the statements inside while
			assemblyCodes+="\tJMP "+label1+"\n";
			
			assemblyCodes+=("\t"+label2+":\n");

			$$->setCode(assemblyCodes);
		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  	{
	  		$$=new SymbolInfo("println","nonterminal");
	  		
			assemblyCodes=("\n\tMOV AX, "+$3->getName()+stoi(table.getCurrentID())+"\n");
			assemblyCodes+=("\tCALL PRINT_ID\n");

			$$->setCode(assemblyCodes);
		}
	  | RETURN expression SEMICOLON
	    {
			$$=new SymbolInfo(codes,"statement");

			isReturning=true;
			isReturningType=$2->getVariableType();
		}
	  ;
	  
expression_statement : SEMICOLON {
			$$=new SymbolInfo("SEMICOLON","SEMICOLON");
		}			
			| expression SEMICOLON {
			$$=$1;
		} 
			;
	  
variable : ID
		{
			$$=$1;

			$$->setIdentity("var");
			$$->idx=-1;

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
			
			$$->idx=stoi($3->getName());

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
			$$=$1;

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
		

			//-------------------------------------------------------------
			//#code generation
			//cout<<$1->getName()<<" "<<$1->idx<<endl;
			
			assemblyCodes=$3->getCode()+$1->getCode();
			assemblyCodes+=("\n\tMOV AX, "+$3->getName()+"\n");
			string temp=$1->getName()+stoi(table.getCurrentID());

			if($1->idx==-1){
				assemblyCodes+=("\tMOV "+temp+", AX\n");
			}

			//array
			else{
				assemblyCodes+=("\tMOV "+temp+"+"+stoi($1->idx)+"*2, AX\n");
			}

			$$->setCode(assemblyCodes);
			$$->setName(temp);
			//-------------------------------------------------------------

		}
	   ;
			
logic_expression : rel_expression
		{
			$$=$1;
		} 	
		 | rel_expression LOGICOP rel_expression 	
		{
			$$=$1;

			//------------------------------------------------------------------
			//#semantic: LOGICOP MUST BE INT
			$$->setVariableType("int");

			//#semantic: both sides of RELOP should be integer
			if($1->getVariableType()!="int" || $3->getVariableType()!="int"){
				semanticErr++;
				fprintf(error,"semantic error in line %d found: both operands of %s should be integers\n\n",line,$2->getName().c_str());
			}
			//------------------------------------------------------------------


			//------------------------------------------------------------------
			//code generation
			assemblyCodes=$$->getCode()+$3->getCode();
			
			string temp=newTemp();
			string label1=newLabel();
			string label2=newLabel();

			assemblyCodes+=("\n\tMOV AX, "+$1->getName()+"\n");
			assemblyCodes+=("\tMOV BX, "+$3->getName()+"\n");

			if($2->getName()=="&&"){
				assemblyCodes+=("\tCMP AX, 1\n");
				assemblyCodes+=("\tJNE "+label1+"\n");
				
				assemblyCodes+=("\tCMP BX, 1\n");
				assemblyCodes+=("\tJNE "+label1+"\n");

				assemblyCodes+=("\tMOV AX, 1\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
				assemblyCodes+=("\tJMP "+label2+"\n");
				
				assemblyCodes+=("\n\t"+label1+":\n");
				assemblyCodes+=("\tMOV AX, 0\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
				
				
				assemblyCodes+=("\n\t"+label2+":\n");
			}

			else if($2->getName()=="||"){
				assemblyCodes+=("\tCMP AX, 1\n");
				assemblyCodes+=("\tJE "+label1+"\n");
				
				assemblyCodes+=("\tCMP BX, 1\n");
				assemblyCodes+=("\tJE "+label1+"\n");
				
				assemblyCodes+=("\tMOV AX, 0\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
				assemblyCodes+=("\tJMP "+label2+"\n");
				
				assemblyCodes+=("\n\t"+label1+":\n");
				assemblyCodes+=("\tMOV AX, 1\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
				
				assemblyCodes+=("\n\t"+label2+":\n");
			}

			$$->setCode(assemblyCodes);
			$$->setName(temp);
			//------------------------------------------------------------------
		}
		 ;
			
rel_expression : simple_expression 
		{
			$$=$1;
		}
		| simple_expression RELOP simple_expression	
		{
			$$=$1;

			//------------------------------------------------------------------
			//#semantic: RELOP MUST BE INT
			$$->setVariableType("int");

			//#semantic: both sides of RELOP should be integer
			if($1->getVariableType()!="int" || $3->getVariableType()!="int"){
				semanticErr++;
				fprintf(error,"semantic error in line %d found: both operands of %s should be integers\n\n",line,$2->getName().c_str());
			}
			//------------------------------------------------------------------


			//------------------------------------------------------------------
			//code generation
			//here two expressions are already in two variables, we compare them
			//if true send them to label1, else assign false to the new temp and jump to label2
			//from label1 assign true, eventually it will get down to label2

			assemblyCodes=$$->getCode()+$3->getCode();
			
			assemblyCodes+=("\n\tMOV AX, "+$1->getName()+"\n");
			assemblyCodes+=("\tCMP AX, "+$3->getName()+"\n");

			string temp=newTemp();
			string label1=newLabel();
			string label2=newLabel();

			if($2->getName()=="<"){
				assemblyCodes+=("\tJL "+label1+"\n");
			}
			
			else if($2->getName()=="<="){
				assemblyCodes+=("\tJLE "+label1+"\n");
			}

			else if($2->getName()==">"){
				assemblyCodes+=("\tJG "+label1+"\n");	
			}
				
			else if($2->getName()==">="){
				assemblyCodes+=("\tJGE "+label1+"\n");	
			}
				
			else if($2->getName()=="=="){
				assemblyCodes+=("\tJE "+label1+"\n");	
			}
				
			else{
				assemblyCodes+=("\tJNE "+label1+"\n");	
			}
				
			assemblyCodes+=("\n\tMOV "+temp+", 0\n");
			assemblyCodes+=("\tJMP "+label2+"\n");

			assemblyCodes+=("\n\t"+label1+":\n\tMOV "+temp+", 1\n");
			assemblyCodes+=("\n\t"+label2+":\n");
				
			$$->setName(temp);
			$$->setCode(assemblyCodes);

			delete $3;
			//------------------------------------------------------------------
		}
		;
				
simple_expression : term
		{
			$$=$1;
		} 
		  | simple_expression ADDOP term
		{
			$$=$1;

			if($1->getVariableType()=="float" || $3->getVariableType()=="float")
				$$->setVariableType("float");
			else
				$$->setVariableType("int");

			
			assemblyCodes=$$->getCode();
			assemblyCodes+=$3->getCode();

			// move one of the operands to a register
			//perform addition or subtraction with the other operand and 
			//move the result in a temporary variable  
			
			string temp=newTemp();	
			if($2->getName()=="+"){
				assemblyCodes+=("\n\tMOV AX, "+$1->getName()+"\n");
				assemblyCodes+=("\tADD AX, "+$3->getName()+"\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
			}
			
			else{
				assemblyCodes+=("\n\tMOV AX, "+$1->getName()+"\n");
				assemblyCodes+=("\tSUB AX, "+$3->getName()+"\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
			}
		
			$$->setCode(assemblyCodes);
			$$->setName(temp);

			delete $3;
		} 
		  ;
					
term :	unary_expression
		{
			$$=$1;
		}
     |  term MULOP unary_expression
		{
			$$=$1;
			assemblyCodes=$$->getCode();

			//------------------------------------------------------------------------
			//code generation	
			assemblyCodes += $3->getCode();
			assemblyCodes += "\n\tMOV AX, "+ $1->getName()+"\n";
			assemblyCodes += "\tMOV BX, "+ $3->getName() +"\n";
			
			string temp=newTemp();

			if($2->getName()=="*"){
				assemblyCodes += "\tMUL BX\n";
				assemblyCodes += "\tMOV "+temp+", AX\n";
			}

			else if($2->getName()=="/"){
				// clear dx, perform 'div bx' and mov ax to temp
				assemblyCodes += "\tXOR DX, DX\n";
				assemblyCodes += "\tDIV BX\n";
				assemblyCodes += "\tMOV "+temp+" , AX\n";
			}

			else{
				// "%" operation clear dx, perform 'div bx' and mov dx to temp
				assemblyCodes += "\tXOR DX, DX\n";
				assemblyCodes += "\tDIV BX\n";
				assemblyCodes += "\tMOV "+temp+" , DX\n";
				
			}

			$$->setName(temp);
			$$->setCode(assemblyCodes);

			//------------------------------------------------------------------------


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
			$$=$2;
			string temp=newTemp();

			//codes like "+const" or "+var" or "-const" or "-var"
			//need actions only for negs
			if($1->getName()=="-"){
				assemblyCodes=$$->getCode();
				assemblyCodes+=("\n\tMOV AX, "+$2->getName()+"\n");
				assemblyCodes+=("\tNEG AX\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
			}

			else{
				assemblyCodes=$$->getCode();
				assemblyCodes+=("\n\tMOV AX, "+$2->getName()+"\n");
				assemblyCodes+=("\tMOV "+temp+", AX\n");
			}

			$$->setCode(assemblyCodes);
			$$->setName(temp);
		}  
		 | NOT unary_expression 
		{
			$$=$2;

			//codes like !const or !var_name
			string temp=newTemp();

			assemblyCodes=$$->getCode();
			assemblyCodes+=("\n\tMOV AX, "+$2->getName()+"\n");
			assemblyCodes+=("\tNOT AX\n");
			assemblyCodes+=("\tMOV "+temp+", AX\n");

			$$->setCode(assemblyCodes);
			$$->setName(temp);
		}
		 | factor 
		{
			$$=$1;
		}
		 ;
	
factor : variable
		{
			$$=new SymbolInfo($1->getName(),$1->getType());
			
			//copy all properties
			$$->sz=$1->sz;
			$$->setVariableType($1->getVariableType());
			$$->setReturnType($1->getReturnType());
			$$->setCode($$->getCode());
			$$->setIdentity($1->getIdentity()) ;

			//-------------------------------------------------------------------
			//for code generation purpose we concatenate the current id with the variable name
			$$->setName($$->getName()+stoi(table.getCurrentID())); 
			//-------------------------------------------------------------------

			//#semantic error check
			SymbolInfo *temp=table.lookUp($1->getName());
			if(!temp){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable %s not declared in this scope\n\n",line,$1->getName().c_str());
			}
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
			//-----------------------------------------------------------------
			//#semantic error check
			SymbolInfo *temp=table.lookUp($1->getName());
			if(!temp){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable %s not declared in this scope\n\n",line,$1->getName().c_str());
			}
			//-----------------------------------------------------------------


			//-----------------------------------------------------------------
			//code generation
			else
			{
				$$=new SymbolInfo($1->getName(),$1->getType());
			
				//copy all properties
				$$->sz=$1->sz;
				$$->setVariableType($1->getVariableType());
				$$->setReturnType($1->getReturnType());
				$$->setCode($$->getCode());
				$$->setIdentity($1->getIdentity()) ;

				assemblyCodes=$$->getCode();
				string var_name=$1->getName()+stoi(table.getCurrentID());

				$$->setName(var_name);

				//array
				if(temp->sz){
					//idx+1 th element will be accessed using array_name+idx*2

					assemblyCodes+=("\tMOV AX, "+var_name+"+"+stoi($1->idx)+"*2\n");
					assemblyCodes+=("\tINC AX\n");
					assemblyCodes+=("\tMOV "+var_name+"+"+stoi($1->idx)+"*2, AX\n");
				}
				
				else{
					assemblyCodes+=("\tMOV AX, "+var_name+"\n");
					assemblyCodes+=("\tINC AX\n");
					assemblyCodes+=("\tMOV "+var_name+", AX\n");
				}
				
				$$->setCode(assemblyCodes);
			}
			//-----------------------------------------------------------------
		} 
	| variable DECOP
		{
			//-----------------------------------------------------------------
			//#semantic error check
			SymbolInfo *temp=table.lookUp($1->getName());
			if(!temp){
				semanticErr++;
				fprintf(error,"semantic error found in line %d: variable %s not declared in this scope\n\n",line,$1->getName().c_str());
			}
			//-----------------------------------------------------------------


			//-----------------------------------------------------------------
			//code generation
			else
			{
				$$=new SymbolInfo($1->getName(),$1->getType());
			
				//copy all properties
				$$->sz=$1->sz;
				$$->setVariableType($1->getVariableType());
				$$->setReturnType($1->getReturnType());
				$$->setCode($$->getCode());
				$$->setIdentity($1->getIdentity()) ;

				assemblyCodes=$$->getCode();
				string var_name=$1->getName()+stoi(table.getCurrentID());
				string temp_str=newTemp();

				$$->setName(var_name);

				//array
				if(temp->sz){
					//idx+1 th element will be accessed using array_name+idx*2

					assemblyCodes+=("\tMOV AX, "+var_name+"+"+stoi($1->idx)+"*2\n");
					assemblyCodes+=("\tMOV "+temp_str+", AX\n");
					assemblyCodes+=("\tDEC AX\n");
					assemblyCodes+=("\tMOV "+var_name+"+"+stoi($1->idx)+"*2, AX\n");
				}
				
				else{
					assemblyCodes+=("\tMOV AX, "+var_name+"\n");
					assemblyCodes+=("\tMOV "+temp_str+", AX\n");
					assemblyCodes+=("\tDEC AX\n");
					assemblyCodes+=("\tMOV "+var_name+", AX\n");
				}
				
				$$->setCode(assemblyCodes);
				$$->setName(temp_str);
			}
			//-----------------------------------------------------------------
			
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

