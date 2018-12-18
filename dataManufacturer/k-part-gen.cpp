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

// [st,ed)
std::vector<edge> gen_part_edges(
    const std::vector<int>& distribution, 
    int st, 
    int ed, 
    std::vector<edge>& res) 
{
    std::vector<int> half_edge;
    for (int j = 1; j <= ed-st; ++j) {
        // insert distribution[j-1] numbers, which all are "st+j". 
        half_edge.insert(half_edge.end(), distribution[j-1], st+j);
    }
    random_shuffle(half_edge.begin(), half_edge.end());

    std::vector<edge> part;
    for (int i = 0; i+1 < half_edge.size(); i+=2) {
        if (half_edge[i] == half_edge[i+1])
            continue;
        part.push_back(edge(half_edge[i], half_edge[i+1]));
        part.push_back(edge(half_edge[i+1], half_edge[i]));
    }
    for (int i = st+1; i < ed; ++i) {
        part.push_back(edge(i,i+1));
        part.push_back(edge(i+1,i));
    }
    sort(part.begin(), part.end(), edge());
    part.erase(unique(part.begin(), part.end()), part.end());

    res.insert(res.end(), part.begin(), part.end());
    return part;
}

std::vector<edge> gen_edges(int n, int p) {
    std::vector<int> distribution = normal_distribution_seq((n+p-1)/p);
    std::vector<edge> res;
    for (int i = 0; i < p - 1; ++i) {
        gen_part_edges(distribution, n/p*i, n/p*(i+1), res);
    }
    gen_part_edges(distribution, n/p*(p-1), n, res);

    return res;
}
void renum(std::vector<edge> &edges, int n) {
    std::vector<int> v(n+1, 0);
    for (int i = 0; i <= n; ++i) {
        v[i] = i;
    }
    random_shuffle(v.begin() + 1, v.end());
    for (auto &e : edges) {
        e.u = v[e.u];
        e.v = v[e.v];
    }
    sort(edges.begin(), edges.end(), edge());
}

void out1(const std::vector<edge> &edges, std::string filename) {
    std::ofstream ofs(filename);
    for(auto e : edges) {
        ofs << e.u << " " << e.v << std::endl;
    }
}

void out2(const std::vector<edge> &edges, std::string filename, int n) {
    std::ofstream ofs(filename);
    ofs << n << " " << edges.size()/2;

    int last = 0;
    for(auto e : edges) {
        while (last < e.u) {
            ofs << std::endl;
            last ++;
        }
        ofs << e.v << " ";
    }
    while (last <= n) {
        ofs << std::endl;
        last ++;
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
    out1(edges, "newdata.txt");
    renum(edges, n);
    out1(edges, "data.txt");
    out2(edges, "metisdata.txt", n);
    return 0;
}

