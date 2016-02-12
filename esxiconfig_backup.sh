#!/bin/sh
## esxiconf_backup.sh
## Author: James White (james@jmwhite.co.uk)
## Version 0.1
##
## Description:
## Creates a backup of the ESXi host config
## Downloads the generated backup and stores it in the specified directory
## Adds unique datestamp for storing multiple backup copies
## More info about the ESXi config backup be found here:
## http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2042141
##

# Change this to a valid VMFS/NFS path of your choosing
# Avoid using temporary storage locations on ESXi itself
BACKUP_DIR="/vmfs/volumes/DataStore/esxiconf_backups"

cd "${BACKUP_DIR}" || echo "Cannot switch to specified backup directory" exit 1

# Hostname values
HOSTNAME=$(hostname)
HOSTNAME_FQDN=$(hostname -f)

# For the output of the backup.tgz file
DATE_TIMESTAMP=$(date +"%F_%H-%M-%S")
TGZ_FILE="configBundle_${HOSTNAME}_${DATE_TIMESTAMP}.tgz"

echo "Syncing config..."
vim-cmd hostsvc/firmware/sync_config

echo "Generating ESXi config backup..."
CREATE_BACKUP_CMD=$(vim-cmd hostsvc/firmware/backup_config)
# We need to extract the http url and add in the set hostname of ESXi to form a valid URL for wget
BACKUP_HTTP_PATH=$(echo "${CREATE_BACKUP_CMD}"| awk '{ print $7 }' | sed "s/*/${HOSTNAME_FQDN}/g")

echo "Downloading generated ESXi config backup archive..."
wget -q -O "${TGZ_FILE}" "${BACKUP_HTTP_PATH}"

if [ $? -ne 0 ] ; then
	echo "Couldn't download ESXi config backup"
	exit 1
fi

echo "ESXi config backup has been successfully downloaded"
exit 0
