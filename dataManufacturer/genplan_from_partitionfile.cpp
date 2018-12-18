#include <iostream>
#include <fstream>
#include <vector>
#include <map>
void out(std::ofstream &ofs, std::map<int, std::vector<int>>& m) {

	for (int i = 0; m.find(i) != m.end(); ++i) {
		if (i!=0) {
			ofs << ",";
		}
		ofs << "\"" << i << "\": \"";
		int st = m[i][0];
		int last = m[i][0];
		for (int j = 1; j < m[i].size(); ++j) {
			if (m[i][j] == last+1) {
				last ++;
			}
			else {
				ofs << st << "-" << last+1 << ",";
				st = last = m[i][j];
			}
		}
		ofs << st << "-" << last+1 << "\"" << std::endl;
	}
}

int main(int argc, char **argv) {
	std::ios::sync_with_stdio(false);
	
	if(argc != 2) {
		std::cerr << "usage: " << std::string(argv[0]) << " filename" << std::endl
            << "input file: output of metis or commgraph, partition file which used to gen plan.json " << std::endl;
	}
	std::ifstream ifs(argv[1]);
	std::ofstream ofs("plan.json");
	std::map<int, std::vector<int>> m;
	int x, i = 1;

	while(ifs >> x) {
		m[x].push_back(i++);
	}

	ofs << "{" << std::endl
  		<< "\t\"partition_plan\": {\"tables\": {" << std::endl
    	<< "\t\t\"user_profiles\": {\"partitions\": {" << std::endl;
    out(ofs,m);
	ofs << "\t\t}}," << std::endl
		<< "\t\t\"followers\": {\"partitions\": {" << std::endl;
	out(ofs,m);
	ofs << "\t\t}}," << std::endl
		<< "\t\t\"follows\": {\"partitions\": {" << std::endl;
	out(ofs,m);
    ofs << "\t}}}}," << std::endl
  		<< "\t\"default_table\": \"user_profiles\"" << std::endl
  		<< "}" << std::endl;
}
