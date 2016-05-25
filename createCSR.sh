#!/bin/bash
#
#     Utility to create Certificate Signed Requests
#     Bob Brandt <projects@brandt.ie>        
#

_version=1.1
     ESC=$( echo -en "\033" )
BOLD_RED="${ESC}[1;31m"
  NORMAL=$( echo -en "${ESC}[m\017" )

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

function usage() {
    local _exitcode=${1-0}
    local _output=2
    [ "$_exitcode" == "0" ] && _output=1
    [ "$2" == "" ] || echo -e "$2"
	( echo -e "Usage: $0 [options] domain [domain [domain]...]"
	  echo -e " -e, --email        email address"
	  echo -e " -k, --key          key filename (default: domain.key)"
	  echo -e " -p, --pass         password for an existing key"
	  echo -e " -r, --remove       remove password from key"
	  echo -e " -c, --csr          csr filename (default: domain.csr)"
	  echo -e " -b, --bytes        byte size (default: rsa:4096)"
	  echo -e " -h, --help         display this help and exit"
	  echo -e " -v, --version      output version information and exit" ) >&$_output
    exit $_exitcode
}

# Execute getopt
if ! _args=$( getopt -o e:k:p:rc:b:vh -l "email:,key:,pass:,remove,csr:,bytes:,help,version" -n "$0" -- "$@" 2>/dev/null ); then
    _err=$( getopt -o e:k:p:rc:b:vh -l "email:,key:,pass:,remove,csr:,bytes:,help,version" -n "$0" -- "$@" 2>&1 >/dev/null )
    usage 1 "${BOLD_RED}$_err${NORMAL}"
fi

#Bad arguments
# [ $? -ne 0 ] && usage 1 "${BOLD_RED}$0: No arguments supplied!${NORMAL}"

eval set -- "$_args";

# _email="admin@opw.ie"
_email=""
_key=""
_pass=""
_remove=""
_csr=""
_bytes="rsa:4096"

while /bin/true ; do
    case "$1" in
        -e | --email )   _email="$2" ; shift ;;
        -k | --key )     _key="$2" ; shift ;;
        -p | --pass )    _pass="$2" ; shift ;;
        -r | --remove )  _remove="yes" ;;
        -c | --csr )     _csr="$2" ; shift ;;
        -b | --bytes )   _bytes="$2" ; shift ;;
        -h | --help )    usage 0 ;;
        -v | --version ) brandt_version $_version ;;
        -- )             shift ; break ;;
        * )              usage 1 "${BOLD_RED}$0: Invalid argument!${NORMAL}" ;;
    esac
    shift
done

[ -z "$_key" ] && _key="$1.key"
[ -z "$_csr" ] && _csr="$1.csr"

_domains=$( echo "$@" | xargs | sed 's|\s\+|,|g' )
[ -z "$_domains" ] && usage 1 "${BOLD_RED}$0: No domains supplied!${NORMAL}"
[ -n "$_pass" ] && [ ! -f "$_key" ] && usage 1 "${BOLD_RED}$0: Password only used on existing keys!${NORMAL}"
[ -n "$_remove" ] && [ ! -n "$_pass" ] && usage 1 "${BOLD_RED}$0: To remove a password one must be given!${NORMAL}"

_CNs=""
_SAN=""
_DNS=""
declare countDNS=1
IFS=","
for _domain in ${_domains}; do
	_CNs="${_CNs}/CN=${_domain}"
	_SAN="${_SAN}&dns=${_domain}"
	_DNS="${_DNS},DNS.$(( countDNS++ ))=${_domain}"
	if [[ ! $_domain == *.* ]];	then
		_CNs="${_CNs}/CN=${_domain}.opw.ie"
		_CNs="${_CNs}/CN=${_domain}.i.opw.ie"
		_SAN="${_SAN}&dns=${_domain}.opw.ie"
		_SAN="${_SAN}&dns=${_domain}.i.opw.ie"
		_DNS="${_DNS},DNS.$(( countDNS++ ))=${_domain}.opw.ie"
		_DNS="${_DNS},DNS.$(( countDNS++ ))=${_domain}.i.opw.ie"
	fi	
done
_SAN="san:${_SAN:1}"
_DNS="subjectAltName=${_DNS:1}"

_subj="/C=IE/ST=Dublin/L=Dublin/O=Office of Public Works/OU=ICT Unit"
[ -n "$_email" ] && _subj="${_subj}/emailAddress=${_email}"
_subj="${_subj}${_CNs}/${_DNS}"

_config=$( cat /etc/ssl/openssl.cnf )
_config="${_config}\n[SAN]\n${_DNS}"

if [ -f "$_key" ]; then
	echo "The key file (${_key}) does exist."
	if [ -n "$_pass" ]; then
		_pass="-passin pass:${_pass}"
		if [ -n "$_remove" ]; then
			echo "Removing passphrase from key"
			openssl rsa -in ${_key} ${_pass} -out ${_key}
			_pass=""
		fi
	fi
	echo "Creating CSR"
	openssl req -new -key ${_key} -out ${_csr} ${_pass} -batch -subj "${_subj}" -config <( echo -e "$_config" )
else
	echo "The key file (${_key}) does not exist."
	openssl req -new -newkey ${_bytes} -nodes -keyout ${_key} -out ${_csr} -batch -subj "${_subj}" -config <( echo -e "$_config" )
fi
echo "Writing new Certificate Signed Request (CSR) to '${_csr}'"

echo -e "\nVisit: https://ca-i.i.opw.ie/certsrv/certrqxt.asp"
cat "${_csr}"
echo -e "Additional Attributes"
echo -e "${_SAN}\n"