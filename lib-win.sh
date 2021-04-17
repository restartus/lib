#!/usr/bin/env bash
##
## Windows functions that are called from bash
## assumes that include.sh is called so log_verbose is available
##

## Note the if makes sure we only source once which is more efficient

# create a variable that is just the filename without an extension
lib_name="$(basename "${BASH_SOURCE%.*}")"
# dashes are not legal in bash names
lib_name=${lib_name//-/_}
#echo trying $lib_name
# This is how to create a pointer by reference in bash so
# it checks for the existance of the variable named in $lib_name
# not how we use the escaped $ to get the reference
#echo eval [[ -z \${$lib_name-} ]] returns
#eval [[ -z \${$lib_name-} ]]
#echo $?
if eval "[[ ! -v $lib_name ]]"; then
	# how to do an indirect reference
	eval "$lib_name=true"

	# win_sudo powerscript commands
	# set VERBOSE to not exit
	# requires choco install psutils
	win_sudo() {
		if (( $# < 1 )); then return; fi
		#local NOEXIT=""
		#if $VERBOSE; then
			#NOEXIT="-noexit"
		#fi
		log_verbose "running powershell.exe sudo $*"
		#log_verbose powershell.exe Start-Process powershell.exe -Verb RunAs \
			#-ArgumentList "('$NOEXIT $*')"
		#powershell.exe Start-Process powershell.exe -Verb RunAs \
			#-ArgumentList "('$NOEXIT $*')"
		powershell.exe sudo "$@"
	}
fi
