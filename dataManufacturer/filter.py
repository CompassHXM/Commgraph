#!/usr/bin/python
# -*- coding: UTF-8 -*-

import argparse
from os.path import getsize
from operator import itemgetter

default_out_file_name = "filter_output.txt"

def parse_args():
	parser = argparse.ArgumentParser(
		usage=			"%(prog)s [options] in_file_name\n"
						"e.g.: %(prog)s -s twitter_rv.net\n"
						"Try using '-h' or '--help' for more informations.\n\n",
		description=	"Tool that sort all edges and/or remove nodes whose number greater then n in txt graph file.",
		epilog=			"lalala this is epilog."
		)
	parser.add_argument("in_file_name",
						help="name of file which needed to filter.")
	
	parser.add_argument("-s","--sort", action='store_true',
						help="sort edges.")
	parser.add_argument("-f","--filter", type=int,
						help="specfic n and filter out numbers beyond n.")
	parser.add_argument("-o","--out_file_name", default = default_out_file_name,
						help="name of file which stores filter result.")

	args = parser.parse_args()

	if args.filter == None and args.sort == False:
		parser.error("No operation specficed: -s/-f")

	try:
		f = open(args.in_file_name)
	except IOError:
		parser.error("Cannot read '%s'." % args.in_file_name)
	else:
		f.close()

	print args.in_file_name
	return args

class Progress():
	def __init__(self, time):
		self.init(time)

	def init(self,time):
		self.max_time = time
		self.progrss = 0
		self.batch = 0
		self.prompt_size = self.max_time/20

	def step_prompt(self,step):
		self.progrss += step
		print "%.2f%%" % (float(self.progrss)*100.0/float(self.max_time))

	def batch_step_prompt(self,step):
		self.batch += step
		if self.batch >= self.prompt_size:
			self.progrss += self.batch
			self.batch = 0
			print "%.2f%%" % (float(self.progrss)*100/float(self.max_time))

	def prompt(self,done_time):
		if done_time - self.progrss >= self.prompt_size:
			self.progrss = done_time
			print "%.2f%%" % (float(self.progrss)*100/float(self.max_time))

def sort(in_file_name,out_file_name):
	ll = []
	print "reading"
	with open(in_file_name,'r') as infile:
		for line in infile:
			l = line.split()
			ll.append( (int(l[0]),int(l[1])) )

	print "sorting"
	ll.sort(key=itemgetter(0,1))

	print "writing"
	with open(out_file_name,'w') as outfile:
		for edge in ll:
			print >> outfile, "%d %d" % (edge[0],edge[1])

def filter(in_file_name,out_file_name,n):
	with open(in_file_name,'r') as infile:
		with open(out_file_name,'w') as outfile:
			p1=Progress(n)
			for line in infile:
				lst = map(int,line.split())
				if lst[0] <= n and lst[1] <= n:
					print >> outfile, "%d %d" % (lst[0],lst[1])
				if lst[0] > n:
					break
				p1.prompt(lst[0])

	print 'finish'

def main():
	args = parse_args()
	# reref = input_edge(args.in_file_name)
	# output_edge(args.in_file_name,args.out_file_name,reref)
	if args.filter != None:
		filter(args.in_file_name,args.out_file_name,args.filter)
	elif args.sort == True:
		sort(args.in_file_name, args.out_file_name)

if __name__ == '__main__':
	main()
