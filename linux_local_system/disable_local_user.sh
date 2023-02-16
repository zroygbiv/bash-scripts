#!/bin/bash
#
# This script disables, deletes, and/or archives users on a local system

readonly ARCHIVE_DIR='/archive'

usage() {
	# Display usage and exit
	echo "Usage: ${0} [-dra] USER [USERN]..." >&2
	echo 'Disable a local Linux account:' >&2
	echo '  -d  Deletes accounts' >&2
	echo '  -r  Removes the home directory associated w/ account(s)' >&2
	echo '  -a  Creates an archive of the home directory associated w/ account(s)' >&2
	exit 1
}

# Check if script was executed with superuser privileges
if [[ "${UID}" -ne 0 ]]
then
	echo 'Please run with sudo or as root.' >&2
	exit 1
fi

# Parse with options
while getopts dra OPTION
do
	case ${OPTION} in
		d) DELETE_USER='true' ;;
		r) REMOVE_OPTION='-r' ;;
		a) ARCHIVE='true' ;;
		?) usage ;;
	esac
done

# Remove the options while leaving the remaining arguments
shift "$(( OPTIND - 1 ))"

# If the user doesn't supply at least one argument, help user
if [[ "${#}" -eq 0 ]]
then
	usage
fi

# Loop through all usernames supplied as arguments
for USERNAME in "${@}"
do
	echo "Processing user: ${USERNAME}"

	# Check that UID of account is at least 1000
	USERID=$(id -u ${USERNAME})
	if [[ "${USERID}" -lt 1000 ]]
	then
		echo "Refused removal of ${USERNAME} account with UID: ${USERID}." >&2
		exit 1
	fi

# Create an archive if requested to do so
if [[ "${ARCHIVE}" = 'true' ]]
then
	# Check that ARCHIVE_DIR exists
	if [[ ! -d "${ARCHIVE_DIR}" ]]
	then
		echo "Creating ${ARCHIVE_DIR} directory..."
		mkdir -p ${ARCHIVE_DIR}
		if [[ "${?}" -ne 0 ]]
		then
			echo "Unable to create archive directory ${ARCHIVE_DIR}." >&2
			exit 1
		fi
	fi

	# Archive user's home directory, move into ARCHIVE_DIR
	HOME_DIR="/home/${USERNAME}"
	ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
	if [[ -d "${HOME_DIR}" ]]
	then
		echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
		tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
		# Archive unsuccessful
		if [[ "${?}" -ne 0 ]]
		then
			echo "Unable to create ${ARCHIVE_FILE}." >&2
			exit 1
		fi
	else
		echo "${HOME_DIR} does not exist or is not a directory." >&2
		exit 1
	fi
fi

if [[ "${DELETE_USER}" = 'true' ]]
then
	# Delete user
	userdel ${REMOVE_OPTION} ${USERNAME}

	# Check if userdel successsful
	if [[ "${?}" -ne 0 ]]
	then
		echo "Account ${USERNAME} was NOT deleted."
		exit 1
	fi
	echo "Account ${USERNAME} was deleted."
else
	# Disable user
	chage -E 0 ${USERNAME}

	# Check if chage successsful
	if [[ "${?}" -ne 0 ]]
	then
		echo "Account ${USERNAME} was NOT disabled." >&2
		exit 1
	fi
	echo "Account ${USERNAME} was disabled."
fi
done

exit 0
