/*************1505107**************/
/**SymbolInfo, ScopeTable, SymbolTable**/

#include<cstdio>
#include<iostream>
#include<string>
#include<vector>

using namespace std;

typedef unsigned long long int ull;

class SymbolInfo
{
	string name, type, return_type;
	string variable_type, identity;
	string code;
	SymbolInfo *prev, *next;


public:
    int sz;
    vector<SymbolInfo*> edge;
    int *ivalue;float *fvalue; char *cvalue;

	SymbolInfo() {
        this->type="";
        this->name="";
        this->return_type="";
        this->variable_type="";

        ivalue=0; fvalue=0; cvalue=0; sz=0;

		prev = 0;
		next = 0;
	}

	SymbolInfo(string type) {
        this->type=type;
        this->name="";
        this->return_type="";
        this->variable_type="";

        ivalue=0; fvalue=0; cvalue=0; sz=0;

        prev = 0;
		next = 0;
	}

	SymbolInfo(string name, string type) {
		this->name = name;
		this->type = type;
		this->return_type="";
        this->variable_type="";

        ivalue=0; fvalue=0; cvalue=0; sz=0;

		prev = 0;
		next = 0;
	}

	string getName() {
		return name;
	}

	void setName(string name) {
		this->name = name;
	}

	string getType() {
		return type;
	}

	void setType(string type) {
		this->type = type;
	}

	string getReturnType() {
		return return_type;
	}

	void setReturnType(string rtype) {
		this->return_type = rtype;
	}

	string getIdentity() {
        return identity;
	}

	void setIdentity(string identity) {
        this->identity = identity;
	}

	string getVariableType() {
		return variable_type;
	}

	void setVariableType(string variable_type) {
		this->variable_type = variable_type;
	}

	SymbolInfo *getPrev() {
		return prev;
	}

	void setPrev(SymbolInfo *x) {
		prev = x;
	}

	SymbolInfo *getNext() {
		return next;
	}

	void setNext(SymbolInfo *x) {
		next = x;
	}

	void allocateMemory(string choice, int n) {
        if(choice=="int") {
            ivalue=new int[n];
            fill(ivalue,ivalue+n,0);
        }

        else if(choice=="float") {
            fvalue=new float[n];
            fill(fvalue,fvalue+n,0.0);
        }

        else if(choice=="char") {
            cvalue=new char[n];
            fill(cvalue,cvalue+n,'#');
        }
	}

	void setCode(string code){
        this.code=code;
	}

	string getCode(string code){
        return code;
	}
};

class ScopeTable
{
	int n, id;
	SymbolInfo **bucket;
	SymbolInfo *head;
	ScopeTable *parentScope;
public:
	ScopeTable()
	{
		parentScope = 0;
		bucket = 0; head = 0;
	}

	ScopeTable(int n, int id)
	{
		this->n = n;
		this->id = id;

		head = 0;
		bucket = new SymbolInfo*[n];
		for (int i = 0; i < n; i++)
			bucket[i] = 0;

		parentScope = 0;
	}

	//djb2
	int Hash(string s)
	{
		ull h = 5381;
		int l = s.length();

		for (int i = 0; i < l; i++)
			h += ((h * 33) + s[i]);

		return h%n;
	}

	bool Insert(string name, string type)
	{
		if (lookUp(name) != 0)
		{
			//fprintf(logout,"'%s' already Exists In The Current ScopeTable\n",name.c_str());
			return  false;
		}

		SymbolInfo *newSymbol = new SymbolInfo(name, type);
		int hash = Hash(name);

		if (bucket[hash])
		{
			newSymbol->setNext(bucket[hash]);
			bucket[hash]->setPrev(newSymbol);
			bucket[hash] = newSymbol;
		}

		else
			bucket[hash] = newSymbol;

		return true;
	}

	SymbolInfo *lookUp(string name)
	{
		int hash = Hash(name);
		SymbolInfo *temp = bucket[hash];

		while (temp)
		{
			if (temp->getName() == name)
				return temp;

			temp = temp->getNext();
		}

		return 0;
	}

	bool Delete(string name)
	{
		SymbolInfo *del = lookUp(name);

		//not found
		if (del == 0)
			return false;

		SymbolInfo *pre = del->getPrev();
		SymbolInfo *post = del->getNext();

		//deleted node is in the middle
		if (pre)
		{
			pre->setNext(post);
			if (post)
				post->setPrev(pre);
		}

		//head is being deleted
		else
		{
			if (post)
				post->setPrev(pre); //null

			int hash = Hash(name);
			bucket[hash] = post;
		}

		delete del;
		return true;
	}

	void printScopeTable(FILE *logout)
	{
		fprintf(logout, "	------------------------------\n");
		fprintf(logout,"	ScopeTable #%d\n", id);
		SymbolInfo *temp;

		for (int i = 0; i < n; i++)
		{
			if (!bucket[i])
				continue;

			fprintf(logout, "	%d  --> ", i);

			temp = bucket[i];
			while (temp)
			{
				fprintf(logout, "<%s, %s> ", temp->getName().c_str(), temp->getType().c_str());
				temp = temp->getNext();
			}

			fprintf(logout, "\n");
		}

		fprintf(logout, "	------------------------------\n");
	}

	vector<SymbolInfo*> returnAllSymbols()
	 {
        vector<SymbolInfo*> v;
        SymbolInfo *temp;

        for (int i = 0; i < n; i++)
		{
			if (!bucket[i])
				continue;

			temp = bucket[i];
			while (temp)
			{
				v.push_back(temp);
				temp = temp->getNext();
			}
		}

		return v;
	}

	ScopeTable *getParentScopeTable() {
		return parentScope;
	}

	void setParentScopeTable(ScopeTable *x) {
		parentScope = x;
	}

	int getID() {
		return id;
	}

	~ScopeTable()
	{
		for (int i = 0; i < n; i++)
			fr(bucket[i]);

		delete bucket;
	}

	void fr(SymbolInfo *x)
	{
		if (x == 0)
			return;

		if (x->getNext())
			fr(x->getNext());

		delete x;
	}
};

class SymbolTable
{
	int n, id;
	ScopeTable *current, *dell;
	vector<ScopeTable*> v;

public:
	SymbolTable(int n)
	{
		this->n = n;
		id = 0;
		current = 0;

		//global scope
		id++;
		ScopeTable *newScopeTable = new ScopeTable(n, id);

		if (!v.empty())
			newScopeTable->setParentScopeTable(v.back());

		current = newScopeTable;
		v.push_back(newScopeTable);
	}

	void EnterScope(FILE *logout)
	{
		id++;
		ScopeTable *newScopeTable = new ScopeTable(n, id);
		fprintf(logout,"################################\n");
		fprintf(logout,"# ScopeTable with ID %d Created #\n",id);
		fprintf(logout,"################################\n\n");

		if (!v.empty())
			newScopeTable->setParentScopeTable(v.back());

		current = newScopeTable;
		v.push_back(newScopeTable);
	}

	void ExitScope(FILE *logout)
	{
		if (!id)
			return;

		dell = current;
		current = current->getParentScopeTable();
		v.pop_back();

		delete dell;
	}

	bool Insert(string name, string type,FILE *logout)
	{
		if (current)
			return current->Insert(name, type);

		else
		{
			EnterScope(logout);
			return current->Insert(name, type);
		}
	}

	bool Remove(string name)
	{
		if (current)
			return current->Delete(name);

		else
			return false;
	}

	SymbolInfo* lookUp(string name)
	{
		ScopeTable *temp = current;

		for (int i = v.size() - 1; i >= 0; i--)
		{
			if (temp->lookUp(name))
				return temp->lookUp(name);

			temp = temp->getParentScopeTable();
		}

		return 0;
	}

	int getCurrentID() {
        return id;
	}

	vector<SymbolInfo*> printCurrentAndGetAll(FILE *logout){
        vector<SymbolInfo*> v=current->returnAllSymbols();
        current->printScopeTable(logout);
        return v;
	}

	ScopeTable *getGlobalScope(){
        return v[0];
	}

	void PrintCurrentScopeTable(FILE *logout) {
		if (current)
			current->printScopeTable(logout);
	}

	void PrintAllScopeTable(FILE *logout)
	{
		ScopeTable *temp = current;
		fprintf(logout,"------------------------------------------------------------\n");
		while (temp)
		{
			temp->printScopeTable(logout);
			temp = temp->getParentScopeTable();
		}
		fprintf(logout,"------------------------------------------------------------\n");
	}
};
