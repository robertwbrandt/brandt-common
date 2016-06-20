#!/usr/bin/env python
"""
Common Python code used between different projects
"""
import fcntl, termios, struct, os, re, sys
import syslog as SYSLOG

import ldapurl, ldap
from ldap.ldapobject import LDAPObject
from ldap.controls import SimplePagedResultsControl

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
  output = ""

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
    output += separator.join(tmp[i]) + '\n'


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

def formatDN(dn):
  dn = str(dn).strip().lower()
  dn = re.sub("\s+,\s+",",",dn)
  dn = re.sub("\s+=\s+",",",dn)
  return dn

# https://bitbucket.org/jaraco/python-ldap/src/f208b6338a28/Demo/paged_search_ext_s.py
class _PagedResultsSearchObject():
  def paged_search_ext_s(self,base,scope,filterstr='(objectClass=*)',attrlist=None,attrsonly=0,serverctrls=None,clientctrls=None,timeout=-1,sizelimit=0,page_size = 1000):
    """
    Behaves exactly like LDAPObject.search_ext_s() but internally uses the
    simple paged results control to retrieve search results in chunks.
    This is non-sense for really large results sets which you would like
    to process one-by-one
    """
    req_ctrl = SimplePagedResultsControl(True,size=page_size,cookie='')

    # Send first search request
    msgid = self.search_ext(
      base,
      ldap.SCOPE_SUBTREE,
      search_flt,
      attrlist=searchreq_attrlist,
      serverctrls=(serverctrls or [])+[req_ctrl]
    )

    result_pages = 0
    all_results = []
    
    while True:
      rtype, rdata, rmsgid, rctrls = self.result3(msgid)
      all_results.extend(rdata)
      result_pages += 1
      # Extract the simple paged results response control
      pctrls = [
        c
        for c in rctrls
        if c.controlType == SimplePagedResultsControl.controlType
      ]
      if pctrls:
        if pctrls[0].cookie:
            # Copy cookie from response control to request control
            req_ctrl.cookie = pctrls[0].cookie
            msgid = self.search_ext(
              base,
              ldap.SCOPE_SUBTREE,
              search_flt,
              attrlist=searchreq_attrlist,
              serverctrls=(serverctrls or [])+[req_ctrl]
            )
        else:
            break
    return result_pages,all_results

class _MyLDAPObject(LDAPObject,_PagedResultsSearchObject):
  pass

class LDAPSearch(object):
  """ 
  The class returns a List of a Truples of a String and a Dicionary of a List
      
    ldapurl     = ldap[s]://[host[:port]][/base[?[attributes][?[scope][?[filter][?extensions]]]]]
    scope       = "base" / "one" / "sub"
    ldap://ldap.opw.ie:389/o=opw?cn,mail?base
    ldaps://ldap1.opw.ie/ou=userapp,o=opw?cn,mail?sub??bindname=cn=brandtb%2cou=it%2co=opw,X-BINDPW=password
  """
  
  def __init__(self, source = None, ldap_version = None, trace_level = None, debug_level = None, referrals = None):
    self.__source = None
    self.__type = None
    self.__sourcename = None
    self.__result_pages = None
    self.__results = None 
    self.__resultsDict = None
    self.__ldap_version = 3
    self.__trace_level = 0
    self.__debug_level = 0
    self.__referrals = False

    if source != None: self.search(source, ldap_version, trace_level, debug_level, referrals)
 
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
  result_pages = property(lambda self: self.__result_pages)

  def __doNothing(*x): return x[-1]

  def resultsDict(self, functDN = __doNothing, functAttr = __doNothing, functValue = __doNothing):
    if self.__results and not self.__resultsDict:
      self.__resultsDict = {}
      for entry in self.__results:
        if entry and len(entry) == 2:
          dn = functDN(entry[0])
          self.__resultsDict[dn] = {}
          for attr in sorted(entry[1].keys()):
            value = sorted([ functValue(functAttr(attr), v) for v in entry[1][attr] ])
            self.__resultsDict[dn].update( { functAttr(attr): value } )
    return self.__resultsDict

  def search(self, source, ldap_version = None, trace_level = None, debug_level = None, referrals = None):
    timeout = 0
    self.source = source
    self.__results = []
    if self.type == "file" or self.type == "stream":
      ldifFile = ldif.LDIFRecordList(self.__source)
      ldifFile.parse()
      self.__results = ldifFile.all_records

    elif self.type == "url":
      filterstr = self.source.filterstr
      if filterstr == None: filterstr = "(objectClass=*)"
      con_string = "%s://%s" % (self.source.urlscheme, self.source.hostport)    
      extensions = self.source.extensions
      
      if ldap_version != None: self.__ldap_version = int(ldap_version)
      if trace_level != None: self.__trace_level = int(trace_level)
      if debug_level != None: self.__debug_level = int(debug_level)
      if referrals != None: self.__referrals = bool(referrals)
      ldap.set_option(ldap.OPT_DEBUG_LEVEL,self.__debug_level)
      ldap.set_option(ldap.OPT_REFERRALS, self.__referrals)

      l = _MyLDAPObject(con_string,trace_level=self.__trace_level)
      l.protocol_version = self.__ldap_version
      #l.start_tls_s()
      if self.source.who:
        l.simple_bind_s(self.source.who, self.source.cred)
      else:
        l.simple_bind_s('', '') # anonymous bind

      # Send search request
      self.__result_pages, self.__results = l.paged_search_ext_s(
        self.source.dn,
        self.source.scope,
        filterstr,
        attrlist=self.source.attrs,
        serverctrls=None,
        page_size = 1000
      )

      l.unbind_s()
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
    
def syslog(message, ident = "", priority = "info", facility = "syslog", options = []):
  """
  Send a string to syslog and return that same string.
  """
  priority = { "emerg":SYSLOG.LOG_EMERG, "alert":SYSLOG.LOG_ALERT, 
               "crit":SYSLOG.LOG_CRIT, "err":SYSLOG.LOG_ERR, 
               "warning":SYSLOG.LOG_WARNING, "notice":SYSLOG.LOG_NOTICE, 
               "info":SYSLOG.LOG_INFO, "debug":SYSLOG.LOG_DEBUG }.get(str(priority).lower(),0)
  facility = { "kern":SYSLOG.LOG_KERN, "user":SYSLOG.LOG_USER, 
               "mail":SYSLOG.LOG_MAIL, "daemon":SYSLOG.LOG_DAEMON, 
               "auth":SYSLOG.LOG_AUTH, "lpr":SYSLOG.LOG_LPR, 
               "news":SYSLOG.LOG_NEWS, "uucp":SYSLOG.LOG_UUCP, 
               "cron":SYSLOG.LOG_CRON, "syslog":SYSLOG.LOG_SYSLOG, 
               "local0":SYSLOG.LOG_LOCAL0, "local1":SYSLOG.LOG_LOCAL1, 
               "local2":SYSLOG.LOG_LOCAL2, "local3":SYSLOG.LOG_LOCAL3, 
               "local4":SYSLOG.LOG_LOCAL4, "local5":SYSLOG.LOG_LOCAL5, 
               "local6":SYSLOG.LOG_LOCAL6, "local7":SYSLOG.LOG_LOCAL7 }.get(str(facility).lower(),0)
  option = 0
  for opt in options:
    option += { "pid":SYSLOG.LOG_PID, "cons":SYSLOG.LOG_CONS, "ndelay":SYSLOG.LOG_NDELAY, 
                "nowait":SYSLOG.LOG_NOWAIT, "perror":SYSLOG.LOG_PERROR }.get(str(opt).lower(),0)
  message = str(message)
  ident = str(ident)
  if not ident: ident = os.path.basename(sys.argv[0])
  SYSLOG.openlog(ident = ident, logoption = option, facility = facility)
  add = ""
  for line in message.split("\n"):
    if line:
      SYSLOG.syslog(priority, add + line)
      add = " "
  SYSLOG.closelog()
  return message


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
  url = "ldaps://opwdc2:636/"
  base = "dc=i,dc=opw,dc=ie"
  # url = "ldaps://nds2:636/"
  # base = "o=opw"
  search_flt = r'(objectClass=*)'

  searchreq_attrlist=['cn','entryDN','entryUUID','mail','objectClass']

  url = "ldap://opwdc3.i.opw.ie:389/dc=i,dc=opw,dc=ie?cn,mail?sub"
  l = LDAPSearch(url)
  print l.results
