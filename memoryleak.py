#!/usr/bin/env python
"""
Python utility for diagnosing Memory leaks and tracking data over time
"""
import argparse, textwrap, time
import subprocess

# Import Brandt Common Utilities
import sys, os
sys.path.append( os.path.realpath( os.path.join( os.path.dirname(__file__), "/opt/brandt/common" ) ) )
import brandt
sys.path.pop()

args = {}
args['outputfile'] = 'stdout'
args['count'] = 1
args['delay'] = 1
args['processes'] = ''
args['listprocesses'] = False

version = 0.3

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
      print "Usage: " + self.__prog + " [options] [process] [process]..."
      print "Script used to diagnose memory leaks.\n"
      print "Options:"
      options = []
      options.append(("-h, --help",            "Show this help message and exit"))
      options.append(("-v, --version",         "Show program's version number and exit"))
      options.append(("-c, --count COUNT",     "Number of iterations to perform"))
      options.append(("-d, --delay SECONDS",   "Time in seconds to wait between iterations"))
      options.append(("-o, --outputfile FILE", "File to append. (or stdout|stderr)"))
      options.append(("-l, --listprocesses",   "List available processes"))      
      options.append(("process",               "Processes to specifically look at"))
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
  parser.add_argument('-c', '--count',
          required=False,
          default=args['count'],
          type=int,
          help="Number of iterations to perform.")
  parser.add_argument('-d', '--delay',
          required=False,
          default=args['delay'],
          type=int,
          help="Time in seconds to wait between iterations.")
  parser.add_argument('-l', '--listprocesses',
          required=False,
          default=args['listprocesses'],
          action='store_true',
          help="List available processes.")  
  parser.add_argument('processes',
          nargs='*',
          default= args['processes'],
          action='store',
          help="Processes to specifically look at.")
  args.update(vars(parser.parse_args()))
  args['processes'] = [ str(x).lower() for x in args['processes'] ]
  if args['count'] < 1: args['count'] = 1
  if args['delay'] < 1: args['delay'] = 1

def list_processes():
  command='ps -A --sort -rss -o comm | sort -uf'
  p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  out, err = p.communicate()
  if err: raise IOError(err)
  return out

def get_data(memory, swap, processes):
  command = 'free -b'
  p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  out, err = p.communicate()
  if err: raise IOError(err)
  for line in out.split('\n'):
    if line: 
      tmp = line.split()
      if tmp[0].lower()[:3] == "mem":  
        if len(tmp) > 1: memory['total'] = int(tmp[1])
        if len(tmp) > 2: memory['used'] = int(tmp[2])
        if len(tmp) > 3: memory['free'] = int(tmp[3])
        if len(tmp) > 4: memory['shared'] = int(tmp[4])
        if len(tmp) > 5: memory['buffers'] = int(tmp[5])
        if len(tmp) > 6: memory['cached'] = int(tmp[6])
      if tmp[0].lower()[:4] == "swap":
        if len(tmp) > 1: swap['total'] = int(tmp[1])
        if len(tmp) > 2: swap['used'] = int(tmp[2])
        if len(tmp) > 3: swap['free'] = int(tmp[3])

  if processes:
    command = 'ps -A --sort -rss -o comm,pmem,size,vsize'
    p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate()
    if err: raise IOError(err)
    for line in out.split('\n'):
      if line:
        for process in processes.keys():
          if process in str(line).lower():
            tmp = line.split()
            if len(tmp) > 1: processes[process]['mem'] += float(tmp[1])
            if len(tmp) > 2: processes[process]['size'] += int(tmp[2])
            if len(tmp) > 3: processes[process]['vsize'] += int(tmp[3])

  return memory, swap, processes

# Start program
if __name__ == "__main__":
  command_line_args()

  if args['listprocesses']:
    print list_processes()
    sys.exit(0)
  else:
    header = True
    # if str(args['outputfile']).lower() in ['stdout','stderr']: header = False
    if header and os.path.isfile(args['outputfile']): header = False
    memory_blank    = {'total':0, 'used':0, 'free':0, 'shared':0, 'buffers':0, 'cached':0}
    swap_blank      = {'total':0, 'used':0, 'free':0}
    f = sys.stdout
    if str(args['outputfile']).lower() == "stdout":
      f = sys.stdout
    elif str(args['outputfile']).lower() == "stderr":
      f = sys.stderr
    else:
      f = open(args['outputfile'], 'a')

    for c in range(args['count']):
      processes_blank = {}
      for process in args['processes']:
        processes_blank[process] = {'mem':0, 'size':0, 'vsize':0}
      date = str(time.strftime("%Y-%m-%d %H:%M:%S"))
      if header:
        tmp = ['date','memory total','memory used','memory free','memory shared','memory buffers','memory cached','swap total','swap used','swap free']
        for process in sorted(processes_blank.keys()):
          tmp += [process + " memory", process + " size", process + " vsize"]
        f.write(",".join(tmp) + "\n")
        header = False   
      memory, swap, processes = get_data(memory_blank.copy(), swap_blank.copy(), processes_blank.copy())
      tmp = [date, str(memory['total']), str(memory['used']), str(memory['free']), str(memory['shared']), str(memory['buffers']), str(memory['cached']), str(swap['total']), str(swap['used']), str(swap['free'])]
      for process in sorted(processes_blank.keys()):
        tmp += [str(processes[process]['mem']), str(processes[process]['size']), str(processes[process]['vsize'])]

      f.write(",".join(tmp) + "\n")
      if c < max(range(args['count'])): time.sleep(args['delay'])

    if str(args['outputfile']).lower() not in ["stdout","stderr"]:
      f.close()
