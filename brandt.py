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
