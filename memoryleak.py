#!/usr/bin/env python
"""
Python wrapper for zarafa-stats --users and zarafa-admin --details user
"""
import argparse, textwrap, fnmatch, datetime
import xml.etree.cElementTree as ElementTree
import subprocess

# Import Brandt Common Utilities
import sys, os
sys.path.append( os.path.realpath( os.path.join( os.path.dirname(__file__), "/opt/brandt/common" ) ) )
import brandt
sys.path.pop()

args = {}
args['outputfile'] = ''
args['programs'] = ''

version = 0.3
encoding = 'utf-8'

class customUsageVersion(argparse.Action):
  def __init__(self, option_strings, dest, **kwargs):
    self.__version = str(kwargs.get('version', ''))
    self.__prog = str(kwargs.get('prog', os.path.basename(__file__)))
    self.__row = min(int(kwargs.get('max', 80)), brandt.getTerminalSize()[0])
    self.__exit = int(kwargs.get('exit', 0))
    super(customUsageVersion, self).__init__(option_strings, dest, nargs=0)
  def __call__(self, parser, namespace, values, option_string=None):
    # print('%r %r %r' % (namespace, values, option_string))
    if self.__version:
      print self.__prog + " " + self.__version
      print "Copyright (C) 2013 Free Software Foundation, Inc."
      print "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
      version  = "This program is free software: you can redistribute it and/or modify "
      version += "it under the terms of the GNU General Public License as published by "
      version += "the Free Software Foundation, either version 3 of the License, or "
      version += "(at your option) any later version."
      print textwrap.fill(version, self.__row)
      version  = "This program is distributed in the hope that it will be useful, "
      version += "but WITHOUT ANY WARRANTY; without even the implied warranty of "
      version += "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "
      version += "GNU General Public License for more details."
      print textwrap.fill(version, self.__row)
      print "\nWritten by Bob Brandt <projects@brandt.ie>."
    else:
      print "Usage: " + self.__prog + " [options] [program] [program]..."
      print "Script used to track memory leaks.\n"
      print "Options:"
      options = []
      options.append(("-h, --help",            "Show this help message and exit"))
      options.append(("-v, --version",         "Show program's version number and exit"))
      options.append(("-o, --outputfile FILE", "Type of output {text | csv | xml}"))
      options.append(("program",               "Filter to apply to usernames."))
      length = max( [ len(option[0]) for option in options ] )
      for option in options:
        description = textwrap.wrap(option[1], (self.__row - length - 5))
        print "  " + option[0].ljust(length) + "   " + description[0]
      for n in range(1,len(description)): print " " * (length + 5) + description[n]
    exit(self.__exit)
def command_line_args():
  global args, version
  parser = argparse.ArgumentParser(add_help=False)
  parser.add_argument('-v', '--version', action=customUsageVersion, version=version, max=80)
  parser.add_argument('-h', '--help', action=customUsageVersion)
  parser.add_argument('-o', '--outputfile',
          required=False,
          default=args['outputfile'],
          type=str,
          help="File to redirect output.")
  parser.add_argument('programs',
          nargs='*',
          default= args['programs'],
          action='store',
          help="User to retrieve details about.")
  args.update(vars(parser.parse_args()))
  args['programs'] = [ str(x).lower() for x in args['programs'] ]



# Start program
if __name__ == "__main__":
  command_line_args()  

  command = 'free -b'
  p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  out, err = p.communicate()
  if err: raise IOError(err)
  out = out.split('\n')
  mem = {}
  swap = {}

  for line in out:
  	if line: 
	  	tmp = line.split()
  		if tmp[0].lower()[:3] == "mem":  
  			if len(tmp) > 1: mem['total'] = int(tmp[1])
  			if len(tmp) > 2: mem['used'] = int(tmp[2])
  			if len(tmp) > 3: mem['free'] = int(tmp[3])
  			if len(tmp) > 4: mem['shared'] = int(tmp[4])
  			if len(tmp) > 5: mem['buffers'] = int(tmp[5])
  			if len(tmp) > 6: mem['cached'] = int(tmp[6])
  		if tmp[0].lower()[:4] == "swap":
  			if len(tmp) > 1: swap['total'] = int(tmp[1])
  			if len(tmp) > 2: swap['used'] = int(tmp[2])
  			if len(tmp) > 3: swap['free'] = int(tmp[3])

  programs = {}
  if args['programs']:
	  command = 'ps -A --sort -rss -o comm,pmem,size,vsize'
	  p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	  out, err = p.communicate()
	  if err: raise IOError(err)
	  out = out.split('\n')

	  for line in out:
	  	if line:
	  		for arg in args['programs']:
	  			if arg in str(line).lower():
	  				programs[arg] = {'mem':0, 'size':0, 'vsize':0}
	  				tmp = line.split()
		  			if len(tmp) > 1: programs[arg]['mem'] += float(tmp[1])
		  			if len(tmp) > 2: programs[arg]['size'] += float(tmp[2])
		  			if len(tmp) > 3: programs[arg]['vsize'] += float(tmp[3])
  print programs