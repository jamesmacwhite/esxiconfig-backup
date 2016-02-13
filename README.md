# ESXi Config Backup Script

A shell script to generate and download a ESXi config backup to store at a persistent VMFS DataStore or NFS path

This script runs directly in the hypervisor with minimal resources. A config backup will be generated with a unique datestamp appended to the file name for versioning purposes.

This script is mainly useful if you are running ESXi on a USB/SD card and want to easily recover settings if/when the maximum write cycles [http://serverfault.com/questions/549253/what-happens-when-the-usb-key-or-sd-card-ive-installed-vmware-esxi-on-fails](are eventually reached).

#### Install

1. Copy the `esxiconfig_backup.sh` script to a persistent storage location
2. Edit the `BACKUP_PATH` variable to a directory where you will store the backups
3. Add the following line to your `local.sh` file:

```
/bin/echo "0 3 * * * /path/to/esxiconfig_backup.sh -a > /vmfs/volumes/exampledatastore/ESXiConfig-backup-\$(date +%Y-%m-%d-%H%M%S).log" >> /var/spool/cron/crontabs/root
```

Two paths are specified, the first is the full path to the shell script, the second is a persistent storage location for the cron log file, which is optional.

In this example, the config backup will be generated every day at 3 AM. You can adjust the time portion `0 3 * * *` to be anything you like. You can generate your our time/date schedule via a [http://www.csgnetwork.com/crongen.html](CRON calculator). Once an ESXi host is setup the configuration data isn't likely to change too much so setting a schedule per week would be acceptable as well.

(Later versions of the script will automatically insert itself as a cron job if needed)

#### Restoring configiration data

If your ESXi USB/SD Card goes bad in most cases you'll usually get warning signs with either various I/O errors or similar messages in logs. Because ESXi is lightweight it should still be able to mostly function in RAM despite a failing device, allowing you to prepare a new USB/SD card and perform a swap. The recovery process is fairly simple, but does require a small window of downtime to the ESXi host.

General good practice is to install ESXi to a RAID volume with redundancy to avoid hardware failure taking out the host for this specific reason.

1. Power off ESXi host
2. Remove the failed USB or SD Card and replace with new unformatted device
3. Boot ESXi installer and select the new USB/SD card as the installation path
4. Once installed reboot the ESXi host to confirm the ESXi install is running on the new device
5. Setup the Hypervisor with basic network settings allowing you to gain access to the filesystem
6. Enable SSH
7. Using SCP or a similar method, transfer a config backup to the ESXi filesystem such as `/tmp`

Run the following commands:

```
vim-cmd hostsvc/maintenance_mode_enter
vim-cmd hostsvc/firmware/restore_config /tmp/configBundle.tgz
```

Change the `configBundle.tgz` filename to one that matches a real backup name.

A restore of the config will automatically reboot the host. You should then have your ESXi host restored to its previous state on the new system.

**Note:** You must use the same version of ESXi that you are trying to restore the config of. In other words you cannot restore a backup of an ESXi 5 system to a new ESXi 6 system and vice versa. Ensure your new install exactly matches the version your config backup was generated on. 

In later versions of the script the ESXi version will be added to the backup filename to easily label different ESXi version backups.
