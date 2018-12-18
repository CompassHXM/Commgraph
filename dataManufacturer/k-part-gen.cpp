#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <map>
#include <random>
#include <cmath>
#include <algorithm>

bool parse_args(char **argv, int &n, int &p) {
    try{
        n = stoi(std::string(argv[1]));
        p = stoi(std::string(argv[2]));
        if (p <= 0 || n <= 0 || n<p)
            return false;
    }
    catch (...) {
        return false;
    }
    return true;
}

std::vector<int> normal_distribution_seq(int n, int mean = 15, double stddev = 3.0) {
    std::vector <int> res;
    std::random_device rd{};
    std::mt19937 gen{rd()};
    std::normal_distribution<> d{(double)mean, stddev};
 
    while(n-- > 0)
    {
        int x = std::round(d(gen));
        if (x < 0)
            x = 0;
        res.push_back(x);
    }
    return res;
}

class edge {
 public:
    int u,v;
    edge(int a, int b)
        :u(a),v(b) {}
    edge() = default;
    bool operator() (const edge& a, const edge& b) const {
        return (a.u<b.u) || (a.u==b.u && a.v<=b.v);
    }
    bool operator == (const edge& other) const {
        return other.u == u && other.v == v;
    }
};

std::vector<edge> gen_edges(int n, int p) {
    std::vector<int> distribution = normal_distribution_seq((n+p-1)/p);
    std::vector<int> half_edge;
    for (int i = 0; i < p - 1; ++i) {
        int st = n/p*i;
        for (int j = 1; j <= n/p; ++j) {
            // insert distribution[j-1] numbers, which all are "st+j". 
            half_edge.insert(half_edge.end(), distribution[j-1], st+j);
        }
    }

    for (int st = n/p*(p-1)+1; st <= n; ++st) {
        half_edge.insert(half_edge.end(), distribution[st - n/p*(p-1)-1], st);
    }
    random_shuffle(half_edge.begin(), half_edge.end());

    std::vector<edge> res;
    for (int i = 0; i+1 < half_edge.size(); i+=2) {
        res.push_back(edge(half_edge[i], half_edge[i+1]));
        res.push_back(edge(half_edge[i+1], half_edge[i]));
    }
    sort(res.begin(), res.end(), edge());
    res.erase(unique(res.begin(), res.end()), res.end());
    return res;
}
void out1(const std::vector<edge> &edges, std::string filename) {
    std::ofstream ofs(filename);
    for(auto e : edges) {
        ofs << e.u << " " << e.v << std::endl;
    }
}
int main(int argc, char **argv) {
    std::ios::sync_with_stdio(false);
    int n = 0;
    int p = 0;
    if(argc != 3 || parse_args(argv, n, p) == false) {
        std::cerr << "usage: " << std::string(argv[0]) << " n p" << std::endl
            << "n: number of vetices" << std::endl
            << "v: number of Connected Component" << std::endl;
        return -1;
    }
    std::vector<edge> edges = gen_edges(n,p);
    out1(edges, "data.txt");
    //out2(edges, "metisdata.txt");
    return 0;
}
