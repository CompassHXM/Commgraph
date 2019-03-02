/*
# ./actdp -a -i input1.txt -m aggregate1.map -o aggregate1.txt -n1 7 -n2 3
# ./actdp -s -i aggregate1.txt -m aggregate1.map -o reform1.txt -n1 7 -n2 3
*/

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <map>
using namespace std;

class Exception{
public:
	string what;
	Exception(string s = "")
		:what(s) {}
};

class Option{
public:
	// the existence of this option in list
	bool exist;

	// how many args followed with this option
	// -1-> no limited
	// 0-> store_true option
	// any positive int -> the exactly number
	int required_followed;

	vector<string> values;

	string helpmsg;

public:
	Option() = default;

	Option(string help, int req = 1)
		:exist(false), required_followed(req), helpmsg(help) {}

};

class ArgParser{
private:
	string usage;
	string description;
	map<string, Option> options;

public:
	ArgParser(const string &u = "", const string &desc = "")
		:usage(u),description(desc) {}

	ArgParser& add_option(string name, string help, int req = 1) {	
		if (name.length() == 0 || name[0] != '-') {
			cerr << "Can't add option \"" << name << "\"" << endl;
			throw Exception("parser error.");
		}
		options[name] = Option(help, req);
		return *this;
	}

	map<string, Option> parse(int ac, char **av) {
		map<string, Option> args = options;

		for (int i = 1; i < ac; ++i) {
			string cur_op(av[i]);
			if (args.find(cur_op) == args.end()) {
				cerr << "Can't recognize option " << cur_op << endl;
				throw Exception("parser error.");
			}
			else {
				args[cur_op].exist = true;
				if (args[cur_op].required_followed == -1) {
					while ( i+1 < ac && av[i+1][0] != '-' ) {
						args[cur_op].values.push_back(string(av[i+1]));
						i++;
					}
				}
				else {
					while ( i+1 < ac && args[cur_op].values.size() < args[cur_op].required_followed ) {
						args[cur_op].values.push_back(string(av[i+1]));
						i++;
					}
				}
			}
		}

		for (auto i = args.begin(); i != args.end(); ++i) {
			string name = i->first;
			Option op = i->second;
			if (op.required_followed > 0 && op.values.size() != op.required_followed) {
				cerr << "Option " << name << " required " << op.required_followed 
					<< " arguments, but " << op.values.size() << " offered." << endl;
				throw Exception("parser error.");
			}
		}
		return args;
	}
};

void aggregate(int n1, int n2, ifstream& fstream_in, fstream& fstream_mapfile, ofstream& fstream_out)
{
	int a,b;
	vector<pair<int,int>> edges;
	while( fstream_in >> a >> b) {
		
		edges.push_back(pair<int,int>(a,b));
	}

    double expectm = n1 / (n2+0.0001);
    double expectw = edges.size() / (n2+0.0001);

    vector<pair<int,int>> mapvec(n2*1.1, pair<int,int>(0,0));
    int vecid = 0;
    vector<int> inmemmap(n1*1.05, 0);

    int first_id_of_set = 0;
    int weight_of_set = 0;
    int last_vertex = 0;
    int vertex_weight = 0;
    int setid = 0;
    bool flag = false;

    for (int i = 0; i < edges.size(); )
    {
        a = edges[i].first;
        b = edges[i].second;
        ++ i;
        
        if (a > last_vertex)
        {
            // generate a new vertex        
            if (vertex_weight >= expectw * 2)
                flag = true;
            else if( weight_of_set >= expectw || last_vertex-first_id_of_set >= expectm)
                flag = true;
            else if( weight_of_set + vertex_weight >= expectw*2 || last_vertex-first_id_of_set+1 >= expectm*2)
                flag = true;

            if (flag == true)
            {
                flag = false;
                // mapvec.push_back(pair<int,int>(first_id_of_set, last_vertex));
                mapvec[setid++] = pair<int,int>(first_id_of_set, last_vertex);
                // inmemmap.insert(inmemmap.end(), last_vertex - first_id_of_set, vecid);
                for (int j = first_id_of_set; j < last_vertex; ++j) {
                	inmemmap[j] = vecid;
                }

                vecid += 1;
                first_id_of_set = last_vertex;
                weight_of_set = vertex_weight;
                if (n1 < a){
                	cerr << "Id of input file exceed n1='" << n1 << "'." << endl;
                    throw Exception("error");
                }

                expectm = (n1-last_vertex+1) / (n2-vecid+0.0001);
                expectw = (edges.size()-i) / (n2-vecid+0.0001);
            }

            last_vertex = a;
            vertex_weight = 1;
        }
        else if(a == last_vertex)
            vertex_weight += 1;
        else {
        	cerr << ("Ids of input file shall be increasing.") << endl;
            throw Exception("error");
        }
    }
    // mapvec.push_back(pair<int,int>(first_id_of_set, n1));
    mapvec[setid++] = pair<int,int>(first_id_of_set, last_vertex);
    // inmemmap.insert(inmemmap.end(), n1 - first_id_of_set, vecid);
    for (int j = first_id_of_set; j < n1; ++j) {
    	inmemmap[j] = vecid;
    }

    for (auto p : mapvec) {
    	 fstream_mapfile << p.first << " " << p.second << endl;
    }

    // int last = -1;
    // for (auto p : edges) {
    //     if (last != inmemmap[p.second] && inmemmap[p.first] != inmemmap[p.second]) {
    //     	fstream_out << inmemmap[p.first] << " " << inmemmap[p.second] << endl;
    //         last = inmemmap[p.second];
    //     }
    // }         
}

void scatter(ifstream& fstream_in, fstream& fstream_mapfile, ofstream& fstream_out){
	int a,b;
	vector<pair<int,int>> mapvec;
	while(fstream_mapfile >> a >> b) {
		mapvec.push_back(pair<int,int>(a,b));
	}

	while(fstream_in >> a >> b) {
		fstream_out << mapvec[a].first << " " << mapvec[b].first << endl;
	}
}
    

int main(int ac, char **av)
{
	ios::sync_with_stdio(false);

	map<string, Option> args;
    ArgParser parser =  ArgParser(
        	 	        "%(prog)s [-a/-s] [options] file_name\n"
                        "Try using '-h' or '--help' for more informations.\n\n",
        			    "Input1: A .txt graph file with its size N1, output graph size N2\n"
                        "Output1: The .txt aggregation graph file, with a map file\n"
                        "Input2: A .txt aggregation graph file with its size N2, with a map file\n"
                        "Output2: The origin .txt graph file."
        );

    parser.add_option("-a", "Aggregate: Choose mode aggregation: Input1 & Output1\n", 0);

    parser.add_option("-s", "Scattered: Choose mode scattered: Input2 & Output2\n", 0);

    parser.add_option("-i", "Inputfile: input file name\n", 1);

    parser.add_option("-m", "Mapfile: map file name\n", 1);

    parser.add_option("-o", "Outputfile: output graph file name\n", 1);

    parser.add_option("-n1", "N1: the size of graph before aggregation\n", 1);

    parser.add_option("-n2", "N2: the size of graph after aggregation\n", 1);

    try{
    	args = parser.parse(ac,av);
    }
    catch(...) {
    	return -1;
    }

    int n1 = stoi(args["-n1"].values[0]);
    int n2 = stoi(args["-n2"].values[0]);
    if ( n1 < n2 || n1 <= 0 || n2 <= 0) {
        cerr << "graph size invalid. (n1= " << n1 << ", n2=" << n2 <<  ")" << endl;
        return -1;
    }
    n1++;

    ifstream fstream_in(args["-i"].values[0], ifstream::in);
	fstream fstream_mapfile;
	ofstream fstream_out(args["-o"].values[0], ofstream::out);

    if (args["-a"].exist == true && args["-s"].exist == false) {
        fstream_mapfile.open(args["-m"].values[0], fstream::out);
    }
    else if (args["-a"].exist == false && args["-s"].exist == true) {
        fstream_mapfile.open(args["-m"].values[0], fstream::in);
    }
    else {
    	cerr << "Choose exactly one option in '-a' and '-s' please." << endl;
    	return -1;
    }

    if (!fstream_in.is_open()) {
		cerr << "cannot open " << args["-i"].values[0] << endl;
		return -1;
	}
	if (!fstream_mapfile.is_open()) {
		cerr << "cannot open " << args["-m"].values[0] << endl;
		return -1;
	}
	if (!fstream_out.is_open()) {
		cerr << "cannot write " << args["-o"].values[0] << endl;
		return -1;	
	}


    try{
    	if ( args["-a"].exist ) {
        	aggregate(n1, n2, fstream_in, fstream_mapfile, fstream_out);
	    }
	    else {
	        scatter(fstream_in, fstream_mapfile, fstream_out);
	    }
    }
    catch(...) {
    	return -1;
    }
    return 0;
}


