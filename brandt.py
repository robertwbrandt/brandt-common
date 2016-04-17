#!/usr/bin/env python
"""
Common Python code used between different projects
"""
import fcntl, termios, struct, os

def getTerminalSize():
  """
  Returns a tuple containing (rows,columns)
  """
  def ioctl_GWINSZ(fd):
    try:    
      cr = struct.unpack('hh', fcntl.ioctl(fd, termios.TIOCGWINSZ, '1234'))
    except:
      return
    return cr
  cr = ioctl_GWINSZ(0) or ioctl_GWINSZ(1) or ioctl_GWINSZ(2)
  if not cr:
    try:
      fd = os.open(os.ctermid(), os.O_RDONLY)
      cr = ioctl_GWINSZ(fd)
      os.close(fd)
    except:
      pass
  if not cr:
    cr = (os.environ.get('LINES', 25), os.environ.get('COLUMNS', 80))
  return ( int(cr[1]), int(cr[0]) )



def sortDictbyField(d, field):
  """
  Return the sorted keys of a dictionary, based on a specific field of the dictionary
  """
  return sorted(d.keys(), key=lambda x: d[x][field])


def printTable(items, columns, separator="\t"):
  """
  Print a list of values in neat columns
  """  
  tmp = []
  for i in range(0,len(items),columns):
    tmp.append([])
    for j in range(columns):
      if i + j < len(items): 
        tmp[-1].append(str(items[i + j]))
      else:
        tmp[-1].append('')
  
  widths=[]
  for i in range(columns):
    widths.append(max([len(x[i]) for x in tmp]))

  for i in range(len(tmp)):
    for j in range(columns):
      tmp[i][j] = tmp[i][j].ljust(widths[j])
    print separator.join(tmp[i])

  



class find(object):

  BlockFile = property( lambda self: 'b' )
  CharacterFile = property( lambda self: 'c' )
  Directory = property( lambda self: 'd' )
  PipeFile = property( lambda self: 'p' )
  RegularFile = property( lambda self: 'f' )
  SymbolicLink = property( lambda self: 'l' )
  Socket = property( lambda self: 's' )

  def __setPath(self, path):
    path = str(path)
    if not os.direxists(path): raise IOError, path + " is not a valid path."
    self.__path = path

  def __setIncludes(self, includes):
    if includes:
      pass

  def __setExcludes(self, excludes):
    if excludes:
      pass

  def __setMinFileAge(self, minFileAge):
    if minFileAge:
      pass

  def __setMaxFileAge(self, maxFileAge):
    if maxFileAge:
      pass

  def __setMinFileSize(self, minFileSize):
    if minFileSize:
      pass

  def __setMaxFileSize(self, maxFileSize):
    if maxFileSize:
      pass

  def __setFileTypes(self, fileTypes):
    if fileTypes:
      pass

  def __setDepth(self, depth):
    if depth:
      pass

  def __init__(self, path, includes=None, excludes=None, minFileAge=None, maxFileAge=None, fileTypes= ):
    pass









# Start program
if __name__ == "__main__":
  for root,  dirs, files in os.walk(".", topdown=True):
    print "root", root
    print "dirs", dirs
    print "files", files
    print
