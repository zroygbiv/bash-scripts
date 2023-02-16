#!/bin/bash

# This script creates a new user on the local system.
# Supply a username as an argument to the script.
# Optionally, supply a comment for the account as an argument.
# The script then generates a password for the new account.
# The username, password, and host for the new account will display.
# ${?} - return status
# ${@} - all command arguments
# ${#} - number of arguments
#	& signifies file descriptor
# To login to a newly created account, run: $ su - [USER_NAME]

# Check if script was executed with superuser privileges
if [[ "${UID}" -ne 0 ]]
then
	echo 'Please run with sudo or as root.' >&2
	exit 1
fi

# Check if user supplied at least one argument
if [[ "${#}" -eq 0 ]]
then
	echo "Usage: ${0} USER_NAME [COMMENT]..." >&2
	exit 1
fi

# First parameter (username)
USER_NAME="${1}"

# Comments, drop first parameter, capture remaining
shift
COMMENT="${@}"

# Generate account password
PASSWORD=$(date +%s%N | sha256sum | head -c32)

# Create new account
useradd -c "${COMMENT}" -m ${USER_NAME} &> /dev/null

# Check if useradd succeeded
if [[ "${?}" -ne 0 ]]
then
	echo 'Account could not be created.' >&2
	exit 1
fi

# Set password
echo ${PASSWORD} | passwd --stdin ${USER_NAME} &> /dev/null

# Check if passwd succeeded
if [[ "${?}" -ne 0 ]]
then
	echo 'Account password could not be set.' >&2
	exit 1
fi

# Force password change on first account login
passwd -e ${USER_NAME} &> /dev/null

# Display username, password, and host where user was created
echo "username: ${USER_NAME}"
echo
echo "password: ${PASSWORD}"
echo
echo "hostname: ${HOSTNAME}"

exit 0
