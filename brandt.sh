#!/bin/bash
#
#     A collection of scripts and variable definitions that are used with various 
#      Brandt scripts.
#
#     Bob Brandt <projects@brandt.ie>
#

#
# Do _not_ be fooled by non POSIX locale
LC_ALL=POSIX
export LC_ALL

# Set Special Characters
     ESC=$( echo -en "\033" )
  NORMAL=$( echo -en "${ESC}[m\017" )
    EXTD="${ESC}[1m"
NO_COLOR="${ESC}[0m]"
      UP="${ESC}[1A"

# http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
# https://wiki.archlinux.org/index.php/Color_Bash_Prompt

# Normal Colors
 BLACK="${ESC}[0;30m"
   RED="${ESC}[0;31m"
 GREEN="${ESC}[0;32m"
YELLOW="${ESC}[0;33m"
  BLUE="${ESC}[0;34m"
PURPLE="${ESC}[0;35m"
  CYAN="${ESC}[0;36m"
 WHITE="${ESC}[0;37m"

# Regular Colors
       BOLD=$( tput bold )
 BOLD_BLACK="${ESC}[1;30m"
   BOLD_RED="${ESC}[1;31m"
 BOLD_GREEN="${ESC}[1;32m"
BOLD_YELLOW="${ESC}[1;33m"
  BOLD_BLUE="${ESC}[1;34m"
BOLD_PURPLE="${ESC}[1;35m"
  BOLD_CYAN="${ESC}[1;36m"
 BOLD_WHITE="${ESC}[1;37m"

# Underline Colors
 UNDER_BLACK="${ESC}[4;30m"
   UNDER_RED="${ESC}[4;31m"
 UNDER_GREEN="${ESC}[4;32m"
UNDER_YELLOW="${ESC}[4;33m"
  UNDER_BLUE="${ESC}[4;34m"
UNDER_PURPLE="${ESC}[4;35m"
  UNDER_CYAN="${ESC}[4;36m"
 UNDER_WHITE="${ESC}[4;37m"

# Background Colors
 ON_BLACK="${ESC}[40m"
   ON_RED="${ESC}[41m"
 ON_GREEN="${ESC}[42m"
ON_YELLOW="${ESC}[43m"
  ON_BLUE="${ESC}[44m"
ON_PURPLE="${ESC}[45m"
  ON_CYAN="${ESC}[46m"
 ON_WHITE="${ESC}[47m"

# High Intensity Colors
 HIGH_BLACK="${ESC}[0;90m"
   HIGH_RED="${ESC}[0;91m"
 HIGH_GREEN="${ESC}[0;92m"
HIGH_YELLOW="${ESC}[0;93m"
  HIGH_BLUE="${ESC}[0;94m"
HIGH_PURPLE="${ESC}[0;95m"
  HIGH_CYAN="${ESC}[0;96m"
 HIGH_WHITE="${ESC}[0;97m"

# Bold High Intensity Colors
 BOLDHIGH_BLACK="${ESC}[1;90m"
   BOLDHIGH_RED="${ESC}[1;91m"
 BOLDHIGH_GREEN="${ESC}[1;92m"
BOLDHIGH_YELLOW="${ESC}[1;93m"
  BOLDHIGH_BLUE="${ESC}[1;94m"
BOLDHIGH_PURPLE="${ESC}[1;95m"
  BOLDHIGH_CYAN="${ESC}[1;96m"
 BOLDHIGH_WHITE="${ESC}[1;97m"

# High Intensity Background Colors
 ONHIGH_BLACK="${ESC}[0;100m"
   ONHIGH_RED="${ESC}[0;101m"
 ONHIGH_GREEN="${ESC}[0;102m"
ONHIGH_YELLOW="${ESC}[0;103m"
  ONHIGH_BLUE="${ESC}[0;104m"
ONHIGH_PURPLE="${ESC}[0;105m"
  ONHIGH_CYAN="${ESC}[0;106m"
 ONHIGH_WHITE="${ESC}[0;107m"

#
# Function used to determine the actual Lines and Columns of the active terminal display
function brandt_get_dimensions() {
  local _default_lines="${1:-24}"
  local _default_cols="${2:-80}"
  DIMENSIONS=$( stty size 2>/dev/null )
  [ -z "$DIMENSIONS" ] && DIMENSIONS=$( echo -e 'lines\ncols' | tput -S | tr '\n' ' ' | sed 's|\s$||' )
  [ -z "$DIMENSIONS" ] && [ -n "$LINES" ] && [ -n "$COLUMNS" ] && DIMENSIONS="${LINES} ${COLUMNS}"
  [ -z "$DIMENSIONS" ] && DIMENSIONS="${_default_lines} ${_default_cols}"
  LINES=$( echo "$DIMENSIONS" | sed 's|\s.*||' )
  COLUMNS=$( echo "$DIMENSIONS" | sed 's|.*\s||' )
  export DIMENSIONS LINES COLUMNS
  return 0
}
brandt_get_dimensions

# Set Special RC Strings
DEFAULT_INDENT=10
STATUS=$( echo -en "\015${ESC}[${COLUMNS}C${ESC}[${DEFAULT_INDENT}D" )
     rc_done="${STATUS}${BOLD_GREEN}done${NORMAL}"
  rc_running="${STATUS}${BOLD_GREEN}running${NORMAL}"
   rc_failed="${STATUS}${BOLD_RED}failed${NORMAL}"
   rc_missed="${STATUS}${BOLD_RED}missing${NORMAL}"
  rc_skipped="${STATUS}${BOLD_YELLOW}skipped${NORMAL}"
     rc_dead="${STATUS}${BOLD_RED}dead${NORMAL}"
   rc_unused="${STATUS}${EXTD}unused${NORMAL}"
  rc_unknown="${STATUS}${BOLD_YELLOW}unknown${NORMAL}"
  rc_done_up="${ESC}[1A${rc_done}"
rc_failed_up="${ESC}[1A${rc_failed}"
    rc_reset="${NORMAL}${ESC}[?25h"
     rc_save="${ESC}7${ESC}[?25l"
  rc_restore="${ESC}8${ESC}[?25h"

#
# Generic version functions used within Brandt scripts
function brandt_version() {
  local _version
  if [ -n "$1" ]; then
    _version=$1
  elif [ -n "$VERSION" ]; then
    _version=$VERSION
  elif [ -n "$_version" ]; then
    _version=$_version
  else
    _version=0.1
  fi
  echo -e "$( basename $0 ) $_version"
  echo -e "Copyright (C) 2013 Free Software Foundation, Inc."
  echo -e "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
  echo -e "This program is free software: you can redistribute it and/or modify it under"
  echo -e "the terms of the GNU General Public License as published by the Free Software"
  echo -e "Foundation, either version 3 of the License, or (at your option) any later"
  echo -e "version."
  echo -e "This program is distributed in the hope that it will be useful, but WITHOUT ANY"
  echo -e "WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A"
  echo -e "PARTICULAR PURPOSE.  See the GNU General Public License for more details."
  echo -e "\nWritten by Bob Brandt <projects@brandt.ie>."
  exit 0
}

#
# Print out Right Justified text with optional width and color
function brandt_right() {
  local _text="$1"
  local _width="${2-${#_text}}"
  local _color="${3:-$NORMAL}"
  local tmp=""

  brandt_get_dimensions
  tmp=$( echo -en "\015${ESC}[${COLUMNS}C${ESC}[${_width}D" )
  echo "${tmp}${_color}${_text}${NORMAL}"
  return 0
}

#
# Print out Center Justified text with optional width and color
function brandt_center() {
  local _text="$1"
  local _width="${2-${#_text}}"
  local _color="${3:-$NORMAL}"
  local tmp=""

  brandt_get_dimensions
  [[ $COLUMNS -gt $_width ]] && tmp=$(( ( $COLUMNS - $_width ) / 2 ))
  tmp=$( echo -en "\015${ESC}[${tmp}C" )
  echo "${tmp}${_color}${_text}${NORMAL}"
  return 0
}

safe4xml() {
        while read line
        do
                echo -e "$line" | sed -e "s|&|\&amp;|g" -e "s|&|\&amp;|g" -e "s|<|\&lt;|g" -e "s|>|\&gt;|g" -e "s|\"|\&quot;|g" -e "s|'|\&apos;|g" -e "s|^\s*||g" -e "s|\s*$||g"
        done
}

#
# Function used to by bootscripts in status and start/stop script.
# exit status 0)  success
# exit status 1)  generic or unspecified error
# exit status 2)  invalid or excess args
# exit status 3)  unimplemented feature
# exit status 4)  insufficient privilege
# exit status 5)  program is not installed
# exit status 6)  program is not configured
# exit status 7)  program is not running
# exit status *)  unknown (maybe used in future)
function brandt_status() {
  local _status=$?
  local _width=10

  case "${1:-status}" in
    "stop" )
      _array_labels=( "done"        "failed"    "failed"    "missed"    "failed"    "skipped"      "unused"  "failed"    "failed")
      _array_colors=( "$BOLD_GREEN" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_YELLOW" "$NORMAL" "$BOLD_RED" "$BOLD_RED")
      ;;
    "start" )
      _array_labels=( "done"        "failed"    "failed"    "missed"    "failed"    "skipped"      "unused"  "failed"    "failed")
      _array_colors=( "$BOLD_GREEN" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_YELLOW" "$NORMAL" "$BOLD_RED" "$BOLD_RED")
      ;;  
    "installed" )
      _array_labels=( "installed"   "missing"   "failed"    "missed"    "failed"    "skipped"      "unused"  "failed"    "failed")
      _array_colors=( "$BOLD_GREEN" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_YELLOW" "$NORMAL" "$BOLD_RED" "$BOLD_RED")
      ;;
    "configured" )
      _array_labels=( "configured"  "missing"   "failed"    "missed"    "failed"    "skipped"      "unused"  "failed"    "failed")
      _array_colors=( "$BOLD_GREEN" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_YELLOW" "$NORMAL" "$BOLD_RED" "$BOLD_RED")
      ;;
    "kill" )
      _array_labels=( "done"        "failed"    "failed"    "missed"    "failed"    "skipped"      "unused"  "failed"    "failed")
      _array_colors=( "$BOLD_GREEN" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_YELLOW" "$NORMAL" "$BOLD_RED" "$BOLD_RED")
      ;;
    "setup" )
      _array_labels=( "done"        "failed"    "failed"    "missed"    "failed"    "skipped"      "unused"  "failed"    "failed")
      _array_colors=( "$BOLD_GREEN" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_YELLOW" "$NORMAL" "$BOLD_RED" "$BOLD_RED")
      ;;      
    * ) # status
      _array_labels=( "running"     "missed"    "failed"    "missed"    "failed"    "skipped"      "unused"  "failed"    "failed")
      _array_colors=( "$BOLD_GREEN" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_RED" "$BOLD_YELLOW" "$NORMAL" "$BOLD_RED" "$BOLD_RED")
      ;;
  esac

  [[ $_status -lt 0 ]] || [[ $_status -ge ${#_array_labels[*]} ]] && _status=${#_array_labels[*]}
  local _label=${_array_labels[$_status]}
  local _color=${_array_colors[$_status]}

  if test -t 1 && [ "$TERM" != "raw" ] && [ "$TERM" != "dumb" ]; then
    brandt_right "$_label" $_width "$_color"
  else 
    echo "...${_label}"
  fi
  return $_status
}
 
#
# Return a specific value as an exit value
function returnvalue() { test "$1" == "0" && return 0 || return ${2:-$1} ; }

#
# Wrapper script for non "pretty" boot scripts
function brandt_deamon_wrapper() {
  local _status=$?
  local _string="$1"
  local _initd_script="$2"
  local _command=$( lower "$3" )
  local _script_command="$_command"
  local _executable="$4"

  [ "$_command" == "kill" ] && brandt_deamon_wrapper "$_string" "$_initd_script" stop "$_executable"

  case "$_command" in
    "start" )                     _string="Starting ${_string} " ;;
    "try-restart" | "restart" )   _string="Restarting ${_string} " ;;
    "reload" | "force-reload" )   _string="Reloading ${_string} " ;;
    "stop" )                      _string="Stopping ${_string} " ;;
    "kill" )                      _string="Killing ${_string} " ;;
    "installed" )                 _string="Checking if ${_string} is installed " ;;
    "configured" )                _string="Checking if ${_string} is configured " ;;
    "status" )                    _string="Checking for ${_string} " ;;
    "status-process" )            _string="Checking for ${_string} "
                                  _script_command="status" ;;
    "status-checkproc" )            _string="Checking for ${_string} "
                                  _script_command="status" ;;                                  
    "status-web" )                _string="Checking for ${_string} "
                                  _script_command="status" ;;                                  
    * )                           _string="${_string} " ;;
  esac

  echo -n "$_string"
  case "$_command" in
    "kill" )              pkill -9 "$_executable" > /dev/null 2>&1 ;;
    "installed" )         test -x "$_initd_script" ;;
    "configured" )        test -r "$_initd_script" ;;
    "status-process" )    ps -ef | grep -v "grep" | grep "$_initd_script" > /dev/null 2>&1 ;;
    "status-checkproc" )  /sbin/checkproc "$_initd_script" > /dev/null 2>&1 ;;
    "status-web" )        wget --output-document=/dev/null --no-check-certificate "$_initd_script" > /dev/null 2>&1 ;;                        
    * )                   if [ -x "$_initd_script" ]; then
                            $_initd_script "$_script_command" > /dev/null 2>&1
                          else
                            returnvalue 3      
                          fi ;;
  esac
  brandt_status "$_script_command"
  return $?
}

#
# Change string to lowercase
function lower() { echo "$@" | tr "[:upper:]" "[:lower:]" ; return $? ; }

#
# Change string to UPPERCASE
function upper() { echo "$@" | tr "[:lower:]" "[:upper:]" ; return $? ; }

#
# Change string to Proper Case
function proper() { echo "$@" | sed 's|.*|\L&|; s|[a-z]*|\u&|g' ; return $? ; }

#
# Convert LDAP Context to NDS and vice versa
function convertContext() {
  local _option=$( lower "$1" )
  shift 1

  if [ "$_option" == "edir" ]; then
    echo "$@" | sed "s|\([^\\]\),|\1\.|g"
  else
    echo "$@" | sed "s|\([^\\]\)\.|\1,|g";
  fi
  return $?
}

#
# Get User Input
function brandt_get_input() {
    read -p "$1: " ANSWER
    test -z "$ANSWER" && ANSWER="$2"
    case $( lower "$3" ) in
        "lower" )  echo $( lower "$ANSWER" ) ;;
        "upper" )  echo $( upper "$ANSWER" ) ;;
        "proper" ) echo $( proper "$ANSWER" ) ;;
        * )        echo "$ANSWER" ;;
    esac
    return $?
}

#
# Check to see if user is root
function brandt_amiroot() { test "$( id -u )" == "0";  return $? ; }

#
# Return the argument if it is executable, otherwise see if whereis can find it.
function brandt_whereis() { 
  if [ -x "$1" ]; then
    echo "$1"
  else
    whereis -b "$( basename $1 )" 2>/dev/null | sed -e "s|\S*:\s*||" -e "s|\s\+/.*||"
  fi
  return $? 
}

#
# Change Owner and File Permissions in one command
function chownmod() {
  local _status=0  
  ARGS=$(getopt -o cfvR -l "changes,silent,quiet,verbose,recursive" -n "$0" -- "$@")
  eval set -- "$ARGS";

  local _switches=""
  while /bin/true ; do
    case "$1" in
      -c | --changes )          _switches="${_switches}c" ;;
      -f | --silent | --quiet ) _switches="${_switches}f" ;;
      -v | --verbose )          _switches="${_switches}v" ;;
      -R | --recursive )        _switches="${_switches}R" ;;
      -- )               shift ; break ;;
      esac
      shift
  done
  [ -n "$_switches" ] && _switches="-${_switches}"
  local _owner="$1"
  local _mode="$2"
  local _file="$3"

  if [ -n "$_owner" ] && [ -e "$_file" ]; then
    chown $_switches $_owner "$_file"
    _status=$(( $_status | $? ))
  fi
  if [ -n "$_mode" ] && [ -e "$_file" ]; then
    chmod $_switches $_mode "$_file"
    _status=$(( $_status | $? ))
  fi
  return $_status
}

#
# Brandt Echo
function becho() {
  local _status=$?
  local _switch=$( lower "$1" )
  local _output=1
  shift 1
  case $( lower "$_switch" ) in
    "-e" | "--exit" )   [ "$_status" != "0" ] && _output=2
                        echo -e "$@" >&$_output
                        exit $_status
                        ;;
    * )                 echo -e "$@" >&$_output
                        ;; 
  esac
  return $_status
}

#
# Brandt Modify Config (Also modify SysConfig files)
function brandt_modify_config() {
  local _configfile="$1"
  local _variable="$2"
  local _value="$3"
  local _sep="${4:- }"  
  local _path="$5"
  local _description="$6"
  local _type="$7"
  local _default="$8"

  if [ -n "$_default" ]; then
    if [ "$_type" == "string" ]; then
      _default="\"$_default\""
      _value="\"$_value\""        
    fi
  else
    _default="none"
  fi

  if grep "\s*$_variable\W" "$_configfile" > /dev/null 2>&1
  then
    sed -i "s|\s*$_variable\W.*|$_variable$_sep$_value|" "$_configfile"
  else
    if [ -z "$_path" ]; then
      echo -e "$_variable$_sep$_value\n" >> "$_configfile"
    else
      ( echo -e "\n## Path:\t_path"
        echo -e "## Description:\t$_description"
        echo -e "## Type:\t$_type" 
        echo -e "## Default:\t$_default"
        echo -e "#\n$_variable$_sep$_value\n" ) >> "$_configfile"
    fi
  fi
  return 0
}

function trim() { echo "$@" | xargs ; return $? ; }
function ltrim() { echo "$@" | sed "s|^\W*||g" ; return $? ; }
function ltrim() { echo "$@" | sed "s|\W*$||g" ; return $? ; }

#
# Just pause the terminal until a key is pressed
function brandt_pause() { 
    local _prompt=${1:-'Press any key to continue...'}
    read -n1 -r -p "$_prompt" _key
}

#
# Determine if the string is an IP Address
function isIP() {
    local _status=1
    local _ip="$1"
    if [[ $_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS_old=$IFS
        IFS='.'
        _ip=($_ip)
        IFS=$IFS_old
        [[ ${_ip[0]} -le 255 && ${_ip[1]} -le 255 && ${_ip[2]} -le 255 && ${_ip[3]} -le 255 ]]
        _status=$?
    fi
    return $_status
}

#
# Convert an IP Address to a Full Qualified Domain Name
function IP2FQDN() {
    host -W 1 "$1" 2> /dev/null | sed -n -e "s|.*pointer\s*\(\S*\)$|\1|" -e "s|\.$||ip" | head -1
    return $?
}

#
# Convert a host Name to a Full Qualified Domain Name
function Host2FQDN() {
    host -W 1 "$1" 2> /dev/null | sed -n "s|^\(\S*\)\s*.*address.*|\1|ip" | head -1
    return $?    
}

#
# Convert a Full Qualified Domain Name to a Host Name
function FQDN2Host() {
    host -W 1 "$1" 2> /dev/null | sed -n "s|\..*||p" | head -1
    return $?
}

#
# Convert a Full Qualified Domain Name to an IP Address
function Host2IP() {
    host -W 1 "$1" 2> /dev/null | sed -n "s|.*address\s*\(\S*\)$|\1|ip" | head -1
    return $?
}

# Return the difference in days between two given dates
function dateDiff() {
#  _date1=$( echo "$1" | sed "s|^.*,.*,||" )
  local _date1="$1"
  local _date2="$2"
  local _returntype=$( lower "${3:-hours}" )
  local _divisior=1

  case "$_returntype" in
    "seconds" )  _divisior=1 ;;
    "minutes" )  _divisior=60 ;;
    "hours" )    _divisior=3600 ;;
    "days" )     _divisior=86400 ;;
    "weeks" )    _divisior=604800 ;;
    "months" )   _divisior=2592000 ;;
    "years" )    _divisior=31536000 ;;
  esac

  test -z "$_date2" && _date2=$( date -u )

  # _sec1=$( date --date="$_date1" +%s )
  # _sec2=$( date --date="$_date2" +%s )
  # echo "$_sec1"
  # echo "$_sec2"
  # echo $(( ( $_sec2 - $_sec1 ) / (60) ))
  # return 0

  echo $(( ( $(date --date="$_date2" +%s) - $(date --date="$_date1" +%s) ) / $_divisior ))
}

# echo -e "\n${BOLD_RED}This file is a collection of BASH utilities for Brandt scripts${NORMAL}"
# echo -e "Copyright (C) 2011 Free Software Foundation, Inc."
# echo -e "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
# echo -e "This is free software: you are free to change and redistribute it."
# echo -e "There is NO WARRANTY, to the extent permitted by law.\n"
# echo -e "Written by ${HIGH_GREEN}Bob Brandt <projects@brandt.ie>${NORMAL}.\n"
# exit 0
