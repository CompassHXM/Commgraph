#include <iostream>
using namespace std;

int main()
{
	int n,k;
	cout << "input vertex number and partition number:" << endl;
	cin >> n >> k;
	int x = n/k;

	for (int i = 0; i < k-1; ++i)
	{
		cout << "\""<< i << "\": \"" << i*x << "-" << (i+1)*x << "\"," << endl;
	}
	cout << "\"" << k-1 <<"\": \"" << (k-1)*x << "-" << n << "\"" << endl;
	return 0;
}