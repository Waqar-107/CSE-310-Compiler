#define _CRT_SECURE_NO_WARNINGS

/***from dust i have come, dust i will be***/

#include<cstdio>
#include<iostream>
#include<string>
#include<vector>

#define dbg printf("in\n");
#define nl printf("\n");

using namespace std;

typedef unsigned long long int ull;

class SymbolInfo
{
	string name, type;
	SymbolInfo *prev, *next;

public:
	SymbolInfo() {
		prev = 0; 
		next = 0;
	}

	SymbolInfo(string name, string type) {
		this->name = name;
		this->type = type;

		prev = 0;
		next = 0;
	}

	string getName() { 
		return name;
	}

	void setName(string name){
		this->name = name;
	}

	string getType() {
		return type; 
	}

	void setType(string type){
		this->type = type;
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
};

class ScopeTable
{
	int n, id;
	SymbolInfo **bucket;
	SymbolInfo *head;
	ScopeTable *parentScope;
public:
	ScopeTable() {
		parentScope = 0;
	}

	ScopeTable(int n,int id)
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
			return  false;

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

		if (!del)
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

	void printScopeTable()
	{
		SymbolInfo *temp;
		cout << id << "\n___\n";
		for (int i = 0; i < n; i++)
		{
			cout << i << " : ";

			temp = bucket[i];
			while (temp)
			{
				cout << "(" << temp->getName() << ", " << temp->getType() << ")  ";
				temp = temp->getNext();
			}

			cout << endl;
		}
	}

	ScopeTable *getParentScopeTable() {
		return parentScope;
	}

	void setParentScopeTable(ScopeTable *x) {
		parentScope = x;
	}

	~ScopeTable()
	{
		for (int i = 0; i < n; i++)
			fr(bucket[i]);
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
	ScopeTable *current;
	vector<ScopeTable*> v;

public:
	SymbolTable(int n) {
		this->n = n;
		id = 1;
	}

	void EnterScope()
	{
		ScopeTable *newScopeTable = new ScopeTable(n, id);
		id++;

		if (!v.empty())
			newScopeTable->setParentScopeTable(v.back());

		current = newScopeTable;
		v.push_back(newScopeTable);
	}

	void ExitScope() {
		current = v.back()->getParentScopeTable();
		v.pop_back();
	}

	bool Insert(string name, string type)
	{
		if (current)
			return current->Insert(name, type);
		else
		{
			EnterScope();
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

	bool lookUp(string name)
	{
		ScopeTable *temp = current;
		for (int i = v.size() - 1; i >= 0; i--)
		{
			if (temp->lookUp(name))
				return true;

			temp = temp->getParentScopeTable();
		}

		return false;
	}

	void PrintCurrentScopeTable(){
		current->printScopeTable();
	}

	void PrintAllScopeTable()
	{
		ScopeTable *temp = current;
		printf("------------------------------\n");
		while (temp)
		{
			temp->printScopeTable();
			temp = temp->getParentScopeTable();
		}
		printf("------------------------------\n");
	}
};

/*
int main()
{
	freopen("in2.txt", "r", stdin);

	int i, j, k;
	int n, m;
	char t, t2;
	string name, type;

	//n buckets
	cin >> n;
	SymbolTable sm(n);

	while ((cin >> t))
	{
		if (t == 'I')
		{
			cin >> name >> type;

			if (sm.Insert(name, type))
				cout << "<" << name << ", " << type << "> inserted\n";
			else
				cout << "unable to insert\n";
		}

		else if (t == 'L')
		{
			cin >> name;

			if (sm.lookUp(name))
				cout << "Found\n";
			else
				cout << "Not Found\n";
		}

		else if (t == 'D')
		{
			cin >> name;

			if (sm.Remove(name))
				cout << "Deleted Successfully\n";
			else
				cout << "Not Deleted\n";
		}

		else if (t == 'P')
		{
			cin >> t2;

			if (t2 == 'A')
				sm.PrintAllScopeTable();
			else
				sm.PrintCurrentScopeTable();
		}

		else if (t == 'S')
			sm.EnterScope();

		else if (t == 'E')
			sm.ExitScope();
	}

}*/