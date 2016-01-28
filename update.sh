#!/bin/bash
#
#     Utility to update Brandt projects
#     Bob Brandt <projects@brandt.ie>
#          
#

_version=1.2
_brandt_utils=/opt/brandt/common/brandt.sh
_base=/opt/brandt
_location="Work"
_gitURL="https://github.com/robertwbrandt"

[ ! -r "$_brandt_utils" ] && echo "Unable to find required file: $_brandt_utils" 1>&2 && exit 6
. "$_brandt_utils"

function pull() {
	local _dir="$1"
	local _basedir=$( basename "$1" )
	if [ -d "$_dir" ] && [ -d "$_dir/.git" ]; then
		echo "Pulling from $_gitURL/$_basedir.git"
 		pushd "$1"
 		git pull --all -v || git fetch --all -v
		rc=$?
		#git reset --hard origin/master
		popd
		return $rc
	else
		echo "Either directory ($_dir) does not exist or is not a GIT project folder!" >&2
		return 1
	fi
}

function clone() {
	local _dir="$1"
	local _basedir=$( basename "$1" )
	if [ -d "$_dir" ]; then
		echo "The directory ($_dir) already exists!" >&2
		return 1
	else
		echo "Cloning from $_gitURL/$_basedir.git"
		git clone -v "$_gitURL/$_basedir.git" "$_basedir"
		return $rc		
	fi
}


function push() {
	local _dir="$1"
	local _basedir=$( basename "$1" )
	if [ -d "$_dir" ] && [ -d "$_dir/.git" ]; then
		echo "Pushing to $_gitURL/$_basedir.git"
 		pushd "$1"
 		git add --all -v
 		git commit --all -v -m "${_location} $( date '+%Y-%m-%d %H:%M:%S' )"
 		git push --all -v
		rc=$?
		#git reset --hard origin/master
		popd
		return $rc
	else
		echo "Either directory ($_dir) does not exist or is not a GIT project folder!" >&2
		return 1
	fi
}



function usage() {
    local _exitcode=${1-0}
    local _output=2
    [ "$_exitcode" == "0" ] && _output=1
    [ "$2" == "" ] || echo -e "$2"
	( echo -e "Usage: $0 [options] [project]"
	  echo -e "     --pull         pull/load this project"
	  echo -e "     --clone        clone/download this project"		
	  echo -e " -p, --push         push/save this project"
	  echo -e " -h, --help         display this help and exit"
	  echo -e " -v, --version      output version information and exit" ) >&$_output
    exit $_exitcode
}

# Execute getopt
if ! _args=$( getopt -o pvh -l "pull,clone,push,help,version" -n "$0" -- "$@" 2>/dev/null ); then
    _err=$( getopt -o pvh -l "pull,clone,push,help,version" -n "$0" -- "$@" 2>&1 >/dev/null )
    usage 1 "${BOLD_RED}$_err${NORMAL}"
fi

#Bad arguments
#[ $? -ne 0 ] && usage 1 "$0: No arguments supplied!\n"

eval set -- "$_args";

_cmd="pull"

while /bin/true ; do
    case "$1" in
             --pull )      _cmd="pull" ;;
             --clone )     _cmd="clone" ;;
        -p | --push )      _cmd="push" ;;
        -h | --help )      usage 0 ;;
        -v | --version )   brandt_version $_version ;;
        -- )               shift ; break ;;
        * )                usage 1 "${BOLD_RED}$0: Invalid argument!${NORMAL}" ;;
    esac
    shift
done
_project="$1"
shift 1

# If using a Proxy Server
export HTTP_PROXY=http://webproxy.i.opw.ie:3128/
export HTTPS_PROXY=http://webproxy.i.opw.ie:3128/
git config --global http.proxy $HTTP_PROXY
git config --global https.proxy $HTTPS_PROXY

git config --global user.email "bob@brandt.ie"
git config --global user.name "Bob Brandt"

if [ -z "$_project" ]; then
	[ "$_cmd" == "clone" ] && _cmd="pull"
elif [ -d "$_project" ]; then
	_project=$( readlink -f "$_project" )
elif [ -d "$_base/$_project" ]; then
	_project=$( readlink -f "$_base/$_project" )
else
	_project="$_base/$( basename $_project)"
	_cmd="clone"
fi

echo "$( proper ${_cmd}ing ) $_project"

if [ -z "$_project" ]; then
    _status=0
	for dir in $( find "$_base" -maxdepth 1 -mindepth 1 -type d | sort )
	do
	    case "$_cmd" in
	        pull )  pull "$dir" ;;
	        push )  push "$dir" ;;
	    esac		
	    _status=$(( $_status | $? ))
	done
	exit $_status
else
    case "$_cmd" in
        pull )  pull "$_project" ;;
        clone )	clone "$_project" ;;
        push )  push "$_project" ;;
    esac
fi
exit $?
