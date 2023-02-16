#!/bin/bash

# This script creates five generic user accounts for testing
# Test commands
# sudo ./add-test-accounts.sh
# su - user1
# ls -ld /home/user1
# ls -l /archive

# Add accounts for testing
if [[ "${UID}" -ne 0 ]]
then
	'Please run with sudo or as root.' >&2
	exit 1
fi

for U in user1 user2 user3 user4
do
	useradd ${U}
	echo 'pass1234' | passwd --stdin ${U}
done
