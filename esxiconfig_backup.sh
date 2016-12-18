#!/bin/sh
## esxiconf_backup.sh
## Author: James White (james@jmwhite.co.uk)
## Version 0.2
##
## Description:
## Creates a backup of the ESXi host config
## Downloads the generated backup and stores it in the specified directory
## Adds unique datestamp for storing multiple backup copies
## More info about the ESXi config backup be found here:
## http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2042141
##

if [ $# -ne 1 ] ; then
    echo "usage: $0 /vmfs/volumes/datastore/folder"
    exit 1
fi

# Specify backup dir via parameter to avoid editing the script directly
BACKUP_DIR=$1

# Check to make sure path is valid
cd "${BACKUP_DIR}" || echo "Backup directory provided is not accessible" exit 1

# Hostname values
HOSTNAME=$(hostname)
HOSTNAME_FQDN=$(hostname -f)

# ESXi version values
ESXI_VERSION_BASE=$(vmware -v | awk '{ print $3 }' | sed "s/\./-/g")
ESXI_VERSION_BUILD=$(vmware -v | awk '{ print $4 }')

# For the output of the backup.tgz file
DATE_TIMESTAMP=$(date +"%F_%H-%M-%S")
TGZ_FILE="configBundle_${ESXI_VERSION_BASE}-${ESXI_VERSION_BUILD}_${HOSTNAME}_${DATE_TIMESTAMP}.tgz"

echo "Syncing config..."
vim-cmd hostsvc/firmware/sync_config

echo "Generating ESXi config backup..."
CREATE_BACKUP_CMD=$(vim-cmd hostsvc/firmware/backup_config)
# We need to extract the http url and add in the set hostname of ESXi to form a valid URL for wget
BACKUP_HTTP_PATH=$(echo "${CREATE_BACKUP_CMD}"| awk '{ print $7 }' | sed "s/*/${HOSTNAME_FQDN}/g")

echo "Downloading generated ESXi config backup archive..."

if ! wget -q -O "${TGZ_FILE}" "${BACKUP_HTTP_PATH}"
then
	echo "An error occurred while downloading the config backup"
	exit 1
else
	echo "ESXi config backup has been successfully downloaded!"
	exit 0
fi
