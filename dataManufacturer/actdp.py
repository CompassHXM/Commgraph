#!/usr/bin/python
# -*- coding: UTF-8 -*-

# ./actdp.py -a -i input1.txt -m aggregate1.map -o aggregate1.txt -n1 7 -n2 3
# ./actdp.py -s -i aggregate1.txt -m aggregate1.map -o reform1.txt -n1 7 -n2 3

# To install numba at ubuntu:
# sudo apt-get install llvm
# sudo apt-get install python-pip
# sudo -H pip install numba
from __future__ import print_function
import argparse
from numba import jit

@jit
def parse_args():
    parser = argparse.ArgumentParser(
        usage=          "%(prog)s [-a/-s] [options] file_name\n"
                        "Try using '-h' or '--help' for more informations.\n\n",
        description=    "Input1: A .txt graph file with its size N1, output graph size N2\n"
                        "Output1: The .txt aggregation graph file, with a map file\n"
                        "Input2: A .txt aggregation graph file with its size N2, with a map file\n"
                        "Output2: The origin .txt graph file."
        )
    parser.add_argument("-a","--aggregate",    action='store_true',
                                    help="Choose mode aggregation: Input1 & Output1\n")

    parser.add_argument("-s","--scattered", action='store_true',        
                                    help="Choose mode scattered: Input2 & Output2\n")

    parser.add_argument("-i","--input", required=True,
                                    help="input file name\n")

    parser.add_argument("-m","--mapfile", required=True,
                                    help="map file name\n")

    parser.add_argument("-o","--output", required=True,
                                    help="output graph file name\n")

    parser.add_argument("-n1","--n1","--origin_graph_size", type=int, required=True,
                                    help="the size of graph before aggregation\n")

    parser.add_argument("-n2","--n2","--aggregated_graph_size", type=int, required=True,
                                    help="the size of graph after aggregation\n")

    args = parser.parse_args()

    # try:
    #     f = open(args.input)
    # except IOError:
    #     parser.error("Cannot read input file '%s'." % args.input)
    # else:
    #     f.close()

    if args.n1 < args.n2 or args.n1 <= 0 or args.n2 <= 0:
        parse.error("graph size invalid. (n1=%d, n2=%d)" % args.n1, args.n2)
    args.n1 += 1
    if args.aggregate == True and args.scattered == False:
        pass
    elif args.aggregate == False and args.scattered == True:
        # try:
        #     f = open(args.mapfile)
        # except IOError:
        #     parser.error("Cannot read map file '%s'." % args.mapfile)
        # else:
        #     f.close()
        pass
    else:
        parse.error("Choose exactly one option in '-a' and '-s' please.")
    return args

@jit
def aggregate(args):
    f = open(args.input,'r')
    fvec = f.read().split('\n')
    f.close()

    linenum = len(fvec)

    expectm = args.n1 / (args.n2+0.0001)
    expectw = linenum / (args.n2+0.0001)

    mapvec = []
    vecid = 0
    inmemmap = []

    first_id_of_set = 0
    weight_of_set = 0
    last_vertex = 0
    vertex_weight = 0
    line_read = 0

    flag = False

    for line in fvec:
        line_read += 1
        if line == '':
            continue
        vs = map(int,line.split())
        if vs[0] > last_vertex:
            # generate a new vertex        
            if vertex_weight >= expectw * 2:
                flag = True
            elif weight_of_set >= expectw or last_vertex-first_id_of_set >= expectm:
                flag = True
            elif weight_of_set + vertex_weight >= expectw*2 or last_vertex-first_id_of_set+1 >= expectm*2:
                flag = True

            if flag == True:
                flag = False
                mapvec.append([vecid, first_id_of_set, last_vertex])
                for i in range(last_vertex - first_id_of_set):
                    inmemmap.append(vecid)
                vecid += 1
                first_id_of_set = last_vertex
                weight_of_set = vertex_weight
                if args.n1 < vs[0]:
                    print ("Error: Id of input file exceed n1=", args.n1 )
                    return None
                    # raise Exception("Id of input file exceed n1='%d'." % args.n1)

                expectm = (args.n1-last_vertex+1) / (args.n2-vecid+0.0001)
                expectw = (linenum-line_read) / (args.n2-vecid+0.0001)

            last_vertex = vs[0]
            vertex_weight = 1

        elif vs[0] == last_vertex:
            vertex_weight += 1

        else:
            raise Exception("Ids of input file shall be increasing.")

    mapvec.append([vecid, first_id_of_set, args.n1])
    inmemmap.extend( [vecid] * (args.n1 - first_id_of_set) )

    with open(args.mapfile,'w') as fw:
        for [a, b, c] in mapvec:
            print(a, b, c, file=fw)

    #print inmemmap
    with open(args.output,'w') as fw:
        for line in fvec:
            if line == '':
                continue
            vs = map(int,line.split())
            #print "%d %d" % (vs[0], vs[1])
            # if inmemmap[vs[0]] != inmemmap[vs[1]]:
            print(inmemmap[vs[0]], inmemmap[vs[1]], file=fw)
@jit
def scatter(args):
    mapvec = []
    with open(args.mapfile,'r') as f:
        for line in f:
            vs = map(int, line.split())
            mapvec.append(vs)

    with open(args.input,'r') as f:
        with open(args.output,'w') as fw:
            for line in f:
                # vs = map(int, line.split())
                print(mapvec[vs[0]][1], mapvec[vs[1]][1], file=fw)
@jit
def main():
    args = parse_args()
    if args.aggregate == True:
        aggregate(args)
    else:
        scatter(args)

if __name__ == '__main__':
    main()


