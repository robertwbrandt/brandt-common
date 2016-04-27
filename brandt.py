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
  widths=[]

  for i in range(0,len(items),columns):
    tmp.append([])
    for j in range(columns):
      if i + j < len(items): 
        tmp[-1].append(str(items[i + j]))
      else:
        tmp[-1].append('')

  for i in range(columns): widths.append(max([len(x[i]) for x in tmp]))

  for i in range(len(tmp)):
    for j in range(columns):
      tmp[i][j] = tmp[i][j].ljust(widths[j])
    print separator.join(tmp[i])


def proper(string):
  """
  A wrapper for title() but also takes car eof weird Words like MySQL
  """    
  string=str(string).lower().replace("mysql","MySQL")
  return string.title()

allowedASCII = tuple([9,10,13] + range(32,127))
def strXML(string):
  """
  Converts strings to an XML safe string. Basically ripping out every 
  character that is not known to be compatible.
  """    
  global allowedASCII
  return ''.join([ s for s in str(string) if ord(s) in allowedASCII ])

class LDAPSearch(object):
  """ 
  The class returns a List of a Truples of a String and a Dicionary of a List
      
    ldapurl     = ldap[s]://[host[:port]][/base[?[attributes][?[scope][?[filter][?extensions]]]]]
    scope       = "base" / "one" / "sub"
    ldap://ldap.opw.ie:389/o=opw?cn,mail?base
    ldaps://ldap1.opw.ie/ou=userapp,o=opw?cn,mail?sub??bindname=cn=brandtb%2cou=it%2co=opw,X-BINDPW=password
  """
  
  def __init__(self, source = None):
    self.__source = None
    self.__type = None
    self.__sourcename = None
    self.__results = None 
    if source != None:
      self.search(source)
  
  def getSource(self):
    return self.__source

  def setSource(self, source):
    if str(type(source)) == "<type 'str'>" and source == "stdin":
      self.__source = sys.stdin
      self.__type = "stream"
      self.__sourcename = "stdin"            
    elif str(type(source)) == "<type 'file'>":
      self.__source = source
      self.__type = "file"
      self.__sourcename = str(source.name).lstrip("<").rstrip(">")
    elif str(type(source)) == "<type 'str'>":
      try:
        self.__source = ldapurl.LDAPUrl(source)
        self.__type = "url"
        self.__sourcename = source
      except:
        try:
          self.__source = open(source)
          self.__type = "file"
          self.__sourcename = str(source)
        except:
          self.__source = None
          self.__type = None
          self.__sourcename = None
          raise ValueError, "Parameter source does not seem to be a LDAP URL or File."

    else:
      self.__source = None
      self.__type = None
      self.__sourcename = None
      raise ValueError, "Parameter source does not seem to be a LDAP URL or File."

  source = property(getSource, setSource)

  def getType(self):
    if self.__type != None:
      return self.__type
    else:
      raise ValueError, "Source does not seem to be a LDAP URL or File."
      return None
  type=property(getType)

  def getSourceName(self):
    if self.__sourcename != None:
      return self.__sourcename
    else:
      raise ValueError, "Source does not seem to be a LDAP URL or File."
      return None
  sourcename=property(getSourceName)        

  def getresults(self):
    return self.__results
  results = property(getresults)
  
  def search(self, source):
    timeout = 0
    self.source = source
    self.__results = []
    if self.type == "file" or self.type == "stream":
      ldifFile = ldif.LDIFRecordList(self.__source)
      ldifFile.parse()
      self.__results = ldifFile.all_records

    elif self.type == "url":
      filterstr = self.source.filterstr
      #extensions = self.source.extensions
      if filterstr == None: filterstr = "(objectClass=*)"
    
      con_string = "%s://%s" % (self.source.urlscheme, self.source.hostport)    
      l = ldap.initialize(con_string)
      #l.start_tls_s()
      if self.source.who:
        l.bind_s(self.source.who, self.source.cred)
      else:
        l.bind_s('', '') # anonymous bind
  
      ldap_result_id = l.search(self.source.dn, self.source.scope, filterstr, self.source.attrs)
      while 1:
        result_type, result_data = l.result(ldap_result_id, timeout)
        if (result_data == []):
          break
        else:
          if result_type == ldap.RES_SEARCH_ENTRY:
            self.__results.append(result_data[0])
  return self.__results

  def attributelist(self, attribute):
    temp = {}
    for entry in self.results:            
      for attr in entry[1]:
        if attr == attribute:
          for value in entry[1][attr]:
            temp[value] = value            
    return tuple( temp.keys() )
  
  def __str__(self):
    tmp = ""
    if self.results:
      for result in self.results:
        tmp += str(result) + "\n"
    return tmp.strip("\n")
    





# class find(object):

#   BlockFile = property( lambda self: 'b' )
#   CharacterFile = property( lambda self: 'c' )
#   Directory = property( lambda self: 'd' )
#   PipeFile = property( lambda self: 'p' )
#   RegularFile = property( lambda self: 'f' )
#   SymbolicLink = property( lambda self: 'l' )
#   Socket = property( lambda self: 's' )

#   def __setPath(self, path):
#     path = str(path)
#     if not os.direxists(path): raise IOError, path + " is not a valid path."
#     self.__path = path

#   def __setIncludes(self, includes):
#     if includes:
#       pass

#   def __setExcludes(self, excludes):
#     if excludes:
#       pass

#   def __setMinFileAge(self, minFileAge):
#     if minFileAge:
#       pass

#   def __setMaxFileAge(self, maxFileAge):
#     if maxFileAge:
#       pass

#   def __setMinFileSize(self, minFileSize):
#     if minFileSize:
#       pass

#   def __setMaxFileSize(self, maxFileSize):
#     if maxFileSize:
#       pass

#   def __setFileTypes(self, fileTypes):
#     if fileTypes:
#       pass

#   def __setDepth(self, depth):
#     if depth:
#       pass

#   def __init__(self, path, includes=None, excludes=None, minFileAge=None, maxFileAge=None, fileTypes= ):
#     pass









# Start program
if __name__ == "__main__":
  # for root,  dirs, files in os.walk(".", topdown=True):
  #   print "root", root
  #   print "dirs", dirs
  #   print "files", files
  #   print
  printTable(range(10),4)