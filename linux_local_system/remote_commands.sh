#!/bin/bash

# This script executes a given command on multiple servers

# A list of servers
SERVER_LIST='/vagrant/servers'

SSH_OPTIONS='-o ConnectTimeout=2'

usage() {
	echo "Usage: ${0} [-nsv] [-f FILE] COMMAND" >&2
	echo 'Executes COMMAND as single command on each server'
	echo "	-f FILE		Use FILE for list of servers; default ${SERVER_LIST}." >&2
	echo '	-n 		Dry run mode. Display COMMAND that would have been executed and exit.' >&2
	echo '	-s 		Execute COMMAND using sudo on remote server.' >&2
	echo '	-v		Verbose mode. Display server name before executing command.' >&2
	exit 1
}

# Check that script isn't being executed with superuser privileges
if [[ "${UID}" -eq 0 ]]
then
	echo 'Do no execute this script as root; use -s option instead.'
	usage
fi

# Parse options
while getopts f:nsv OPTION
do
	case ${OPTION} in
		f) SERVER_LIST="${OPTARG}" ;;
		n) DRY_RUN='true' ;;
		s) SUDO='sudo' ;;
		v) VERBOSE='true' ;;
		?) usage ;;
	esac
done

# Remove options while leaving remaining arguments
shift "$(( OPTIND - 1))"

# If user doesn't supply at least one argument, provide help
if [[ "${#}" -eq 0 ]]
then
	usage
fi

# Anything that remains on command line to be treated as single COMMAND
COMMAND="${@}"

# Check if SERVER_LIST file exists
if [[ ! -e "${SERVER_LIST}" ]]
then
	echo "Unable to open server list file ${SERVER_LIST}." >&2
	exit 1
fi

# Expect the best, prepare for worst
EXIT_STATUS='0'

# Iterate SERVER_LIST
for SERVER in $(cat ${SERVER_LIST})
do
	if [[ "${VERBOSE}" = 'true' ]]
	then
		echo "${SERVER}"
	fi

	SSH_COMMAND="ssh ${SSH_OPTIONS} ${SERVER} ${SUDO} ${COMMAND}"

	# If dry run, don't execute, just echo
	if [[ "${DRY_RUN}" = 'true' ]]
	then
		echo "DRY RUN: ${SSH_COMMAND}"
	else
		${SSH_COMMAND}
		SSH_EXIT_STATUS="${?}"

		# Capture any non-zero exit status from SSH_COMMAND, report to user
		if [[ "${SSH_EXIT_STATUS}" -ne 0 ]]
		then
			EXIT_STATUS="${SSH_EXIT_STATUS}"
			echo "Execution on ${SERVER} failed." >&2
		fi
	fi
done

exit ${EXIT_STATUS}
