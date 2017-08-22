#!/bin/bash
#
#     Utility to update Brandt projects
#     Bob Brandt <projects@brandt.ie>
#
#

_version=1.2
_brandt_utils=/opt/brandt/common/brandt.sh
_this_script=/opt/brandt/common/update.sh
_this_conf=/etc/brandt/update.conf

[ ! -r "$_brandt_utils" ] && echo "Unable to find required file: $_brandt_utils" 1>&2 && exit 6
. "$_brandt_utils"

if [ ! -f "$_this_conf" ]; then
	mkdir $( dirname "$_this_conf" ) 2> /dev/null
	( echo '#     Configuration file for update script'
	  echo '#     Bob Brandt <projects@brandt.ie>'
	  echo '_base=/opt/brandt'
	  echo '_location="$( hostname )"'
	  echo '_gitURL="https://github.com/robertwbrandt"'
	  echo '_proxy="${HTTPS_PROXY:-HTTP_PROXY}"' ) > "$_this_conf"
fi
. "$_this_conf"

[ ! -L "$_base/update" ] && ln -sf "$_this_script" "$_base/update"


function getUserPass() {
	_user="$1"
	_pass="$2"

	[ -z "$_user" ] && read -p "Enter the username: " _user
	if [ -n "$_user" ] && [ -z "$_pass" ]; then
		read -sp "Enter password for $_user: " _pass
	fi
}

function pull() {
	local _dir="$1"
	local _basedir=$( basename "$1" )
	if [ -d "$_dir" ] && [ -d "$_dir/.git" ]; then
		echo "from $_gitURL/$_basedir.git"
 		pushd "$1" > /dev/null
		getUserPass "$_user" "$_pass"		 		
 		if [ -n "$_user" ]; then
 			echo "Setting username"
 			_gitURL=$( echo "$_gitURL" | sed "s|://|://$_user@|" )
	 		if [ -n "$_pass" ]; then
 				echo "Setting password"
 				_gitURL=$( echo "$_gitURL" | sed "s|@|:$_pass@|" )
 			fi 		
 			git remote set-url origin "$_gitURL/$_basedir.git"
 		fi

		[ -n "$_force" ] && git reset --hard origin/master

 		git pull --all -v || git fetch --all -v
		rc=$?
		popd > /dev/null
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
		echo "from $_gitURL/$_basedir.git"
		getUserPass "$_user" "$_pass"		
 		if [ -n "$_user" ]; then
 			echo "Setting username"
 			_gitURL=$( echo "$_gitURL" | sed "s|://|://$_user@|" )
	 		if [ -n "$_pass" ]; then
 				echo "Setting password"
 				_gitURL=$( echo "$_gitURL" | sed "s|@|:$_pass@|" )
 			fi 			
 		fi
 		git clone -v "$_gitURL/$_basedir.git" "$_basedir"
		return $?	
	fi
}

function push() {
	local _dir="$1"
	local _basedir=$( basename "$1" )
	if [ -d "$_dir" ] && [ -d "$_dir/.git" ]; then
		echo "to $_gitURL/$_basedir.git"
 		pushd "$1" > /dev/null
 		if [ -n "$_user" ] && [ -n "$_pass" ]; then
 			echo "Setting username and password"
 			_gitURL=$( echo "$_gitURL" | sed "s|://|://$_user:$_pass@|" )
 			git remote set-url origin "$_gitURL/$_basedir.git"
 		fi
 		git add --all -v
 		git commit --all -v -m "${_location} $( date '+%Y-%m-%d %H:%M:%S' )"
 		git push --all -v
		rc=$?
		#git reset --hard origin/master
		popd > /dev/null
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
	  echo -e " -u, --user         username for this project (will need password)"
	  echo -e " -p, --push         push/save this project"
	  echo -e " -f, --force        force pull/load this project"
	  echo -e " -h, --help         display this help and exit"
	  echo -e " -v, --version      output version information and exit" ) >&$_output
    exit $_exitcode
}

# Execute getopt
if ! _args=$( getopt -o u:pfvh -l "user:,pull,clone,push,force,help,version" -n "$0" -- "$@" 2>/dev/null ); then
    _err=$( getopt -o u:pfvh -l "user:,pull,clone,push,force,help,version" -n "$0" -- "$@" 2>&1 >/dev/null )
    usage 1 "${BOLD_RED}$_err${NORMAL}"
fi

#Bad arguments
#[ $? -ne 0 ] && usage 1 "$0: No arguments supplied!\n"

eval set -- "$_args";

_cmd="pull"
_user=""
_pass=""
_force=""

while /bin/true ; do
    case "$1" in
             --pull )      _cmd="pull" ;;
             --clone )     _cmd="clone" ;;
        -u | --user )      _user="$2" ; shift ;;
        -p | --push )      _cmd="push" ;;
        -f | --force )     _cmd="pull" ; _force="force" ;;
        -h | --help )      usage 0 ;;
        -v | --version )   brandt_version $_version ;;
        -- )               shift ; break ;;
        * )                usage 1 "${BOLD_RED}$0: Invalid argument!${NORMAL}" ;;
    esac
    shift
done
_project="$1"
shift 1

[ -n "$_user" ] && getUserPass "$_user" "$_pass"

# If using a Proxy Server
if [ -n "$_proxy" ]; then
	_ping=$( echo "$_proxy" | sed 's|.*://\(.*\):.*|\1|' )
	if ping -c 1 "$_ping" > /dev/null
	then
		export HTTP_PROXY=$_proxy
		export HTTPS_PROXY=$_proxy
		git config --global http.proxy $HTTP_PROXY
		git config --global https.proxy $HTTPS_PROXY
	else
		echo "Unable to ping $_ping"
	fi
fi

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

if [ -z "$_project" ]; then
    _status=0
	for _dir in $( find "$_base" -maxdepth 1 -mindepth 1 -type d | sort )
	do
		echo -n "$( proper ${_cmd}ing ) $_dir "
	    case "$_cmd" in
	        pull )  pull "$_dir" ;;
	        push )  push "$_dir" ;;
	    esac
	    _status=$(( $_status | $? ))
	done
	exit $_status
else
	echo -n "$( proper ${_cmd}ing ) $_project "
    case "$_cmd" in
        pull )  pull "$_project" ;;
        clone )	clone "$_project" ;;
        push )  push "$_project" ;;
    esac
fi
exit $?
