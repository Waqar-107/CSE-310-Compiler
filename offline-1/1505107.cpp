/*************1505107**************/
/**SymbolInfo, ScopeTable, SymbolTable**/

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

	void setName(string name) {
		this->name = name;
	}

	string getType() {
		return type;
	}

	void setType(string type) {
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
	int bkt, pos;
	int n, id, t2;
	SymbolInfo **bucket;
	SymbolInfo *head;
	ScopeTable *parentScope;
public:
	ScopeTable()
	{
		parentScope = 0;
		bucket = 0; head = 0;
		t2 = 3;
	}

	ScopeTable(int n, int id)
	{
		this->n = n;
		this->id = id;

		t2 = 3;

		head = 0;
		bucket = new SymbolInfo*[n];
		for (int i = 0; i < n; i++)
			bucket[i] = 0;

		parentScope = 0;
	}

	//set t2 to its default value --> this variable is only required for the output requirements
	void SetT2() {
		t2 = 3;
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
		t2 = 1;
		if (lookUp(name) != 0)
		{
			printf("Already Exists In The Current ScopeTable\n");
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

		printf("Inserted in ScopeTable# %d at position %d, 0\n", id, bkt);
		return true;
	}

	SymbolInfo *lookUp(string name)
	{
		int hash = Hash(name);
		SymbolInfo *temp = bucket[hash];

		pos = 0;
		bkt = hash;
		while (temp)
		{
			if (temp->getName() == name)
			{
				if (t2 != 1)
					printf("Found in ScopeTable# %d at position %d, %d\n", id, bkt, pos);

				return temp;
			}

			temp = temp->getNext();
			pos++;
		}

		if (t2 != 1)
			printf("Not Found\n");

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

		printf("Deleted entry at %d, %d from current ScopeTable\n", bkt, pos);

		delete del;
		return true;
	}

	void printScopeTable()
	{
		printf("ScopeTable #%d\n", id);
		SymbolInfo *temp;

		for (int i = 0; i < n; i++)
		{
			cout << i << " --> ";

			temp = bucket[i];
			while (temp)
			{
				cout << "<" << temp->getName() << " : " << temp->getType() << ">  ";
				temp = temp->getNext();
			}

			printf("\n");
		}
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
	}

	void EnterScope()
	{
		id++;
		ScopeTable *newScopeTable = new ScopeTable(n, id);
		printf("New ScopeTable With Id %d Created\n", id);

		if (!v.empty())
			newScopeTable->setParentScopeTable(v.back());

		current = newScopeTable;
		v.push_back(newScopeTable);
	}

	void ExitScope()
	{
		if (!id)
        {
            printf("No ScopeTable To Remove\n");
            return;
        }

		printf("ScopeTable With Id %d Removed\n", id);
		id--;

		dell=current;
		current=current->getParentScopeTable();
		v.pop_back();

		delete dell;
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
		{
			current->SetT2();
			return current->Delete(name);
		}

		else
			return false;
	}

	bool lookUp(string name)
	{
		ScopeTable *temp = current;

		for (int i = v.size() - 1; i >= 0; i--)
		{
			temp->SetT2();
			if (temp->lookUp(name))
				return true;

			temp = temp->getParentScopeTable();
		}

		return false;
	}

	void PrintCurrentScopeTable() {
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

int main()
{
	freopen("input.txt", "r", stdin);
	freopen("output.txt", "w", stdout);

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
			cout << t << " " << name << " " << type << endl;

			sm.Insert(name, type);
		}

		else if (t == 'L')
		{
			cin >> name;
			cout << t << " " << name << endl;

			sm.lookUp(name);
		}

		else if (t == 'D')
		{
			cin >> name;
			cout << t << " " << name << endl;

			sm.Remove(name);
		}

		else if (t == 'P')
		{
			cin >> t2;
			cout << t << " " << t2 << endl;

			if (t2 == 'A')
				sm.PrintAllScopeTable();
			else
				sm.PrintCurrentScopeTable();
		}

		else if (t == 'S')
			cout << t << endl, sm.EnterScope();

		else if (t == 'E')
			cout << t << endl, sm.ExitScope();

        else
            break;

		cout << endl;
	}

	return 0;
}
