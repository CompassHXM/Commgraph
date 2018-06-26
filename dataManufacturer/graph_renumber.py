#!/usr/bin/python
# -*- coding: UTF-8 -*-

import argparse
from os.path import getsize
from operator import itemgetter


def parse_args():
    parser = argparse.ArgumentParser(
        usage=          "%(prog)s [options] in_file_name\n"
                        "e.g.: %(prog)s -s twitter_rv.net\n"
                        "Try using '-h' or '--help' for more informations.\n\n",
        description=    "Feed a renumber file and a graph file(.txt or .net)\n"
                        "Then give you a renumbered graph file!\n"
        )
    parser.add_argument("graph",    help="name of the graph file, each line contains an edge\n"
                                    "vertex1  vertex2\n"
                                    "...\n"
                                    "vertexx  vertexy\n")

    parser.add_argument("-r","--renumber",  help="name of the renumber file, each line contains a id map\n"
                                            "v1_origin_id  v1_renumber_id\n"
                                            "...\n"
                                            "vn_origin_id  vn_renumber_id\n")

    parser.add_argument("-o","--output",
                                            help="name of file which stores result.")

    args = parser.parse_args()

    if args.renumber == None:
        parser.error("No renumber file specficed: -r/--renumber")

    try:
        f1 = open(args.graph)
        f2 = open(args.renumber)
    except IOError:
        parser.error("Cannot read '%s' or '%s'." % args.graph, args.renumber)
    else:
        f1.close()
        f2.close()
    if args.output == None:
        args.output = args.graph + ".new"

    return args

def dorenumber(args):
    renum = []
    with open(args.renumber,'r') as renumberfile:
        for line in renumberfile:
            t = map(int,line.split())
            if len(t) != 2:
                continue
            if len(renum) <= t[0]:
                renum.extend( [0 for i in range(len(renum), t[0]+1)] )

            renum[int(t[0])] = int(t[1])

    with open(args.graph,'r') as graphfile:
        with open(args.output,'w') as outfile:
            for line in graphfile:
                vs = map(int,line.split())
                print >> outfile, "%d %d" % (renum[vs[0]], renum[vs[1]])
    
    res = []
    with open(args.graph,'r') as graphfile:
        for line in graphfile:
            vs = map(int,line.split())
            res.append((renum[vs[0]], renum[vs[1]]))

    res.sort(key=itemgetter(0,1))

    with open(args.output,'w') as outfile:
        for r in res:
            print >> outfile, "%d %d" % r

    print 'Done.'

def main():
    args = parse_args()
    dorenumber(args)

if __name__ == '__main__':
    main()

