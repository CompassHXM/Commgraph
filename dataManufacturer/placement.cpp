#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
using namespace std;

int LoadLimit = 1000;
int MemLimit = 1000;

class Community {
  public:
	int size, weight;
	Community() = default;
	Community(int _s, int _w)
		:size(_s), weight(_w) {};
	Community operator +(const Community &other) {
		return Community(this->size + other.size, this->weight + other.weight);
	}
	bool operator <=(const Community &other) {
		return (this->size <= other.size && this->weight <= other.weight);
	}
};

typedef Community Partition;

class CommunityMap {
  public:
  	// comm_map[comm_id] includes {sub_id1, sub_id2, ... sub_idk}
  	vector< vector<int> > comm_map; 
  	void push_back(int _subcomm_id, int _comm_id) {
  		if (_comm_id >= comm_map.size())
  			comm_map.resize(_comm_id + 1);
  		comm_map[_comm_id].push_back(_subcomm_id);
  	}
};

class Remap {
  public:
	int pid, node_id;
	Remap() = default;
	Remap(int _pid, int _nid)
		:pid(_pid), node_id(_nid) {};

	bool operator()(const Remap &a, const Remap &b) {
		return (a.pid < b.pid);
	}
};


void dfs_set_plan(int h, int comm_id, const vector<CommunityMap> &hierarchy_comm, 
		const int &parti_id, vector<int> &partition_plan );

bool parseargs(int argc, char **argv, char *&fname_comm, 
		char *&fname_weight, char *&fname_plan);

void output_formatted_partitions(ofstream& fstream_plan, 
		const vector<Partition> &active_partitions );

char default_plan_name[] = "plan.json";


int main(int argc, char **argv) {
	ios::sync_with_stdio(false);

	char *fname_comm = NULL;
	char *fname_weight = NULL;
	char *fname_plan = default_plan_name;
	if ( !parseargs(argc, argv, fname_comm, fname_weight, fname_plan) ) {
		cerr << "usage: " << string(argv[0]) << " node_to_community_map_file "
			<< "[options]" << endl
			<< "options:" << endl
			<< "-w node_weight_file : input weight for nodes" << endl
			<< "-l number : set LoadLimit" << endl
			<< "-m number : set MemLimit" << endl
			<< "-p plan_file : default known as 'plan.json'" << endl;
		return -1;
	}

	ifstream fstream_comm(fname_comm, ifstream::in);
	ifstream fstream_weight;
	ofstream fstream_plan(fname_plan, ofstream::out);

	if (!fstream_comm.is_open()) {
		cerr << "cannot open " << string(fname_comm) << endl;
		return -1;
	}
	if (fname_weight != NULL) {
		fstream_weight.open(fname_weight, ifstream::in);
		if(!fstream_weight.is_open()) {
			cerr << "cannot open " << string(fname_comm) << endl;
			return -1;
		}
	}
	if (!fstream_plan.is_open()) {
		cerr << "cannot write " << string(fname_plan) << endl;
		return -1;	
	}

	// indexed by community id in every hierarchy
	vector< CommunityMap > hierarchy_comm(1); 
	vector< vector<Community> > hierarchy_comm_properties;

	int former_id = 1e+9; //max index
	int subcomm_id, comm_id;

	int node_num = 0, hierarchy = 0;
	cerr << "Getting input" << endl;
	while(fstream_comm >> subcomm_id >> comm_id) {
		// cerr << "input=" << subcomm_id << " " << comm_id << endl;
		if (former_id > subcomm_id) {
			hierarchy_comm.push_back(CommunityMap());
			if (++hierarchy == 2) 
				node_num = former_id;
			cerr << "hierarchy = " << hierarchy << endl;
		}
		hierarchy_comm[hierarchy].push_back(subcomm_id, comm_id);
		former_id = subcomm_id;
	}

	for (int i = 0; i <= node_num; ++i)
		hierarchy_comm[0].push_back(i,i);

	cerr << "calculating weight & size hierarchically" << endl;

	hierarchy_comm_properties.resize(hierarchy + 1);
	hierarchy_comm_properties[0].resize(node_num + 1, Community(1, 1));
	
	if (fname_weight != NULL) {
		int weight;
		for(int i = 0; fstream_weight >> weight && i <= node_num; ++i) {
			hierarchy_comm_properties[0][i].weight = weight;
		}
	}

	for (int i = 1; i <= hierarchy; ++i) {
		auto &cm = hierarchy_comm[i].comm_map;
		for (int comm_id = 0; comm_id < cm.size(); ++comm_id) {
			for (int j = 0; j < cm[comm_id].size(); ++j){
				if (hierarchy_comm_properties[i].size() <= comm_id)
					hierarchy_comm_properties[i].resize(comm_id + 1, Community(0,0));

				hierarchy_comm_properties[i][comm_id]
					= hierarchy_comm_properties[i][comm_id]
					+ hierarchy_comm_properties[i-1][ cm[comm_id][j] ];
			}	
		}
	}

	//check whether containable in one partition
	cerr << "extra check" << endl;
	
	const Partition Limit(MemLimit, LoadLimit);
	for (int i = 0; i < hierarchy_comm_properties[hierarchy].size(); ++i) {
		if ( !(hierarchy_comm_properties[hierarchy][i] <= Limit) ) {
			cerr << "function has no implementation." << endl;
			break;
		}
	}

	vector<int> size_collector;
	//frist fit
	cerr << "frist fit" << endl;
	vector<int> partition_plan(node_num + 1, -1);
	vector<Partition> active_partitions;
	vector<int> community_in_parti(hierarchy_comm_properties[hierarchy].size());

	for (int k = 0; k < hierarchy_comm_properties[hierarchy].size(); ++k) {
		int fit = -1;
		for (int i = 0; i < active_partitions.size(); ++i)
			if (hierarchy_comm_properties[hierarchy][k] + active_partitions[i] <= Limit) {
				fit = i;
				break;
			}

		if (fit == -1) {
			fit = active_partitions.size();
			active_partitions.push_back(Partition(0,0));
		}

		active_partitions[fit] = hierarchy_comm_properties[hierarchy][k] 
								+ active_partitions[fit];

		community_in_parti[k] = fit;
		size_collector.push_back(hierarchy_comm_properties[hierarchy][k].size);
	}
	for (int i = 0; i < hierarchy_comm[hierarchy].comm_map.size(); ++i)
		dfs_set_plan(hierarchy, i, hierarchy_comm, community_in_parti[i], partition_plan);
	
	sort(size_collector.begin(), size_collector.end());

	ofstream fstream_comm_stat("commsize.txt", ofstream::out);
	int count10 = 0,count100 = 0,count1000 = 0,count10000 = 0,count100000 = 0;
	int sum10 = 0,sum100 = 0,sum1000 = 0,sum10000 = 0,sum100000 = 0;
	int count32 = 0,count320 = 0,count3200 = 0,count32000 = 0,count100000p = 0;
	int sum32 = 0,sum320 = 0,sum3200 = 0,sum32000 = 0,sum100000p = 0;
	int countall = 0;
	for (auto &x : size_collector)
	{
		if (x <= 10)
		{
			count10 ++;
			sum10 += x;
		}else if (x <= 32)
		{
			count32 ++;
			sum32 += x;
		}else if (x <= 100)
		{
			count100 ++;
			sum100 += x;
		}else if (x <= 320)
		{
			count320 ++;
			sum320 += x;
		}else if (x <= 1000)
		{
			count1000 ++;
			sum1000 += x;
		}else if (x <= 3200)
		{
			count3200 ++;
			sum3200 += x;
		}else if (x <= 10000)
		{
			count10000 ++;
			sum10000 += x;
		}else if (x <= 32000)
		{
			count32000 ++;
			sum32000 += x;
		}else if (x <= 100000)
		{
			count100000 ++;
			sum100000 += x;
		}else
		{
			count100000p ++;
			sum100000p += x;
		}
		countall += x;
	}

	cerr << "result outputing" << endl;

	fstream_comm_stat
		<<  "size\tcount\tsum" << endl 
		<<  "avg:" << countall / size_collector.size() << "," << size_collector.size() << endl
		<<  "1~10:" << count10 << ","<< sum10 << endl
		<<  "~32:" << count32 << ","<< sum32 << endl
		<<  "~100:" << count100 << ","<< sum100 << endl
		<<  "~320:" << count320 << ","<< sum320 << endl
		<<  "~1000:" << count1000 << ","<< sum1000 << endl
		<<  "~3200:" << count3200 << ","<< sum3200 << endl
		<<  "~10000:" << count10000 << ","<< sum10000 << endl
		<<  "~32000:" << count32000 << ","<< sum32000 << endl
		<<  "~100000:" << count100000 << ","<< sum100000 << endl
		<<  "100000+:" << count100000p << ","<< sum100000p << endl << endl;

	for (auto &x : size_collector)
	{
		fstream_comm_stat << x << endl;
	}


/*
	cerr << "hierarchy_comm_id dump:" << endl;
	for (int i = 0; i <= node_num; ++i) {
		cerr << "#" << i << ": ";
		for (int j = 0; j < hierarchy_comm_id[i].size(); ++j)
		cerr << hierarchy_comm_id[i][j] << " ";
		cerr << endl;
	}

	cerr << "size dump:" << endl;
	for (int i = 0; i <= hierarchy; ++i) {
		cerr << "#" << i << ": ";
		for (int j = 0; j < hierarchy_size[i].size(); ++j)
		cerr << hierarchy_size[i][j] << " ";
		cerr << endl;
	}
	cerr << "weight dump:" << endl;
	for (int i = 0; i <= hierarchy; ++i) {
		cerr << "#" << i << ": ";
		for (int j = 0; j < hierarchy_weight[i].size(); ++j)
		cerr << hierarchy_weight[i][j] << " ";
		cerr << endl;
	}
*/
/*
{
  "partition_plan": {
    "tables": {
      "user_profiles": {
        "partitions": {
          "0": "0-60000",
          "1": "60000-119999"
        }
      },
      "followers": {
        "partitions": {
          "0": "0-60000",
          "1": "60000-119999"
        }
      },
      "follows": {
        "partitions": {
          "0": "0-60000",
          "1": "60000-119999"
        }
      }
    }
  },
  "default_table": "user_profiles"
}
*/
	cerr << "Total " << active_partitions.size() << " partitions in plan." << endl;

	fstream_plan << "{" << endl
				<< "  \"partition_plan\": {" << endl
				<< "    \"tables\": {" << endl
     			<< "      \"user_profiles\": {" << endl
       			<< "        \"partitions\": {" << endl;

	output_formatted_partitions(fstream_plan, active_partitions);
	fstream_plan << "        }" << endl
				<< "      }," << endl
				<< "      \"followers\": {" << endl
				<< "        \"partitions\": {" << endl;
	output_formatted_partitions(fstream_plan, active_partitions);
	fstream_plan << "        }" << endl
				<< "      }," << endl
				<< "      \"follows\": {" << endl
				<< "        \"partitions\": {" << endl;
	output_formatted_partitions(fstream_plan, active_partitions);
	fstream_plan << "         }" << endl
				<< "      }" << endl
				<< "    }" << endl
				<< "  }," << endl
				<< "  \"default_table\": \"user_profiles\"" << endl
				<< "}" << endl;

	cerr << "Saving plan as " << string(fname_plan) << endl;



	vector<Remap> renum;
	for (int i = 0; i < partition_plan.size(); ++i) {
		renum.push_back( Remap(partition_plan[i], i) );
	}
	sort(renum.begin(), renum.end(), Remap());
	//cout << "# renum map:" << endl;
	for (int i = 0; i < renum.size(); ++i) {
		cout << renum[i].node_id << " " << i << endl;
	}
	cerr << "Done." << endl;
	return 0;
}

void dfs_set_plan(int h, int comm_id, const vector<CommunityMap> &hierarchy_comm, 
		const int &parti_id, vector<int> &partition_plan ) {
	auto &the_cm = hierarchy_comm[h].comm_map[comm_id];
	if (h == 1) {
		for (int i = 0; i < the_cm.size(); ++i)
			partition_plan[the_cm[i]] = parti_id;
	}
	else {
		for (int i = 0; i < the_cm.size(); ++i)
			dfs_set_plan(h-1, the_cm[i], hierarchy_comm, parti_id, partition_plan);
	}
}

bool parseargs(int argc, char **argv, char *&fname_comm, char *&fname_weight, char *&fname_plan) {
	for (int i = 1; i < argc; ++i)
	{
		if (argv[i][0] == '-' && i+1 < argc) {
			switch (argv[i][1]) {
				case 'w': case 'W':
					fname_weight = argv[i+1];
					break;
				case 'l': case 'L':
					LoadLimit = stoi(string(argv[i+1]));
					break;
				case 'm': case 'M':
					MemLimit = stoi(string(argv[i+1]));
					break;
				case 'p': case 'P':
					fname_plan = argv[i+1];
					break;
				default:
					cerr << "error: unrecognized command line option '" << string(argv[i]) << "'." << endl;
					return false;
			}
			i ++;
		}
		else {
			if (fname_comm == NULL)
				fname_comm = argv[i];
			else {
				cerr << "error: more than one file specified '" << string(argv[i]) << "'." << endl;
				return false;
			}
		}
	}
	return true;
}

void output_formatted_partitions(ofstream& fstream_plan, 
		const vector<Partition> &active_partitions ) {
/*
			"0": "0-60000",
          	"1": "60000-119999"
*/	
	int sizecount = 0;
	for (int i = 0; i < active_partitions.size(); ++i) {
		fstream_plan << "\"" << i << "\": \""
					<< sizecount << "-" 
					<< sizecount + active_partitions[i].size
					<< "\"";

		sizecount += active_partitions[i].size;
		if (i != active_partitions.size() - 1)
			fstream_plan << ",";
		fstream_plan << endl;
	}
}

