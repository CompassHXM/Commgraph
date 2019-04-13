#include <iostream>
#include <ctime>
#include <cstdlib>
#include <vector>
#include <algorithm>
#include <fstream>
using namespace std;

vector<int> renum;
vector<vector<int>> edges;
vector<vector<int>> old_edges;

void fun(int s,int t,int d){

	for (int i = s+1; i <= t; ++i)
	{
		for (int j = 1; j <= d/2 && i+j<=t; ++j)
		{
			edges[i].push_back(i+j);
			edges[i+j].push_back(i);
		}
		sort(edges[i].begin(), edges[i].end());

		if (++i > t)
			break;
		for (int j = 1; j <= (d+1)/2 && i+j<=t; ++j)
		{
			edges[i].push_back(i+j);
			edges[i+j].push_back(i);
		}
		sort(edges[i].begin(), edges[i].end());
	}
}

int main()
{
	int n,k,d;
	cout << "input vertex number, number of communities and average degree:" << endl;
	cin >> n >> k >> d;

	int x = n/k;
	renum.resize(n+1);
	edges.resize(n+1);
	old_edges.resize(n+1);
	for (int i = 1; i <= n; ++i)
	{
		renum[i] = i;
	}

	srand((unsigned)time(NULL));
	random_shuffle(renum.begin() + 1, renum.end());
	
	ofstream of1("data.txt");
	ofstream of2("data.txt.new");
	for (int i = 0; i < k-1; ++i)
	{
		fun(i*x,(i+1)*x,d);
	}
	fun((k-1)*x,n,d);

	for (int i = 1; i <= n; ++i)
	{
		for(auto x : edges[i])
		{
			of2 << i << " " << x << endl;
			old_edges[renum[i]].push_back(renum[x]);
		}
		sort(edges[renum[i]].begin(), edges[renum[i]].end());
	}

	for (int i = 1; i <= n; ++i)
	{
		for(auto x : old_edges[i])
		{
			of1 << i << " " << x << endl;
		}
	}

	return 0;
}
