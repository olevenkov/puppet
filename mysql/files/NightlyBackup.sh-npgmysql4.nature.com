#!/bin/bash

# NightlyBackup.sh

###### NOTES #######
#
# - If you're running this script for the first time, you may need to create certain directories
#   files, and set permissions on those files and/or dirs or the script may fail
# - If the script is currently executing, it won't run again until it completes
# - If this script runs as root, no username and password is required is .my.cnf is in /root
# - This script should be executed as ROOT only

###### TO DO ######
#
# - Add logic which asks user if they want to overwrite a copy of a db if one currently exists in
#   destination backup location OR create a new db copy, appending date to file
#

###### SHOUT BARF SAFE ######
#
shout() { echo "$0: $*" >&2; }
barf() { shout "$*"; exit 128; }
safe() { "$@" || barf "can not $*"; }

######### SCRIPT CONFIGURATION ########
#
# Checks to see if this script is being executed as root
RunAsRoot=true

# Set the primary backup directory. No trailing slash
BackupLocation="/var/lib/mysql/backups"

# Backup Location for Backup Files and dumps. No trailing slash
DIR1="$BackupLocation/files"

# Backup Location for MySQL Dumps. No Trailing Slash. 
DIR2="$BackupLocation/sqldumps"

# Backup Location for binary and relay logs. No Trailing Slash. 
DIR3="$BackupLocation/logs"

# Temporary Directory
TMPDIR="/var/lib/mysql/tmp"

# Backup Type: (1) SQL Dump (2) File Copy* (3) Both*
# Note: *Will restart the MySQL service 
BackupType=3

# MySQL Username
MyUsername="dbadmin"

# MySQL Password
MyPassword="dbadmin"

# Backup Log Name
BackupLog="$BackupLocation/backup.log"

# Backup Error Log Name
BackupErrorLog="$BackupLocation/backup.err"

# MySQL Dump Error Log Name (Not reltive to the directory path)
MySQLDumpErrorLog="mysqldump.err"

# Set location of lock file
lock_file="$BackupLocation/BackupInProgress.lck"

# MySQL Base Directory
MySQLBaseDir="/var/lib/mysql"

# What's the MySQL Startup Command  (option 2 OR 3)
# MySQL_StartupCMD="/sbin/service mysql start"

# What's the MySQL Shutdown Command  (option 2 OR 3)
# MySQL_ShutdownCMD="/sbin/service mysql stop"

# Directories to Backup. No need to include base dir, data dir OR logs. (option 2 OR 3)
# These directories are assumed to be in the MySQLBaseDir (ie/ var/lib/mysql/etc)
MySQLBackupTheseDirs=( "etc" "scripts" "logs/error" "logs/slow" )

# Uncomment this to include the MySQL Data Directory  (option 2 Or 3)
# *** NOTE *** if checked, MySQL will stop and restart
# IncludeDataDir="true" # STOP's and RESTART's MYSQL

# Uncomment this to include a backup copy of binary log files
# Specify the location of the binary log files
# IncludeBinLogFiles="/var/lib/mysql/logs/bin"

# Databases to backup when performing a MySQL Dump (option 1 OR 3)
# (Add logic in future to scan mysql.information_schema for all dbs and dump individually)
databases=( "mysql" )

# Uncomment to backup every database into one file (option 1 OR 3)
# ** NOTE ** If this is a MASTER server to a slave, you should enable this because of the --master-data command
# which will allow you to easilly find the binary log position
# AllDatabases="true"

# If ALLDatabases=true, uncomment this to lock ALl TABLES (will only flush binary logs once)
# Otherwise, it will lock just the tables it's copying and flush a binary log for each database
# LockAll="true"

# Set runtime interval (in minutes). This script wont execute if
# another backup is already running OR if it's been running longer than this
max_runtime=360 # (6 hours)

# Days to Keep Backups
keepdays=7

# If uncommented, the owner of the backup files will be changed to this user
backupowner="root.root"

# Send Email to
#EmailNotify="who-support@us.nature.com"
EmailNotify="s.adams@us.nature.com"

# Uncomment if this is a DB Master (1), DB Slave (2)
# IsMaster=1

# Uncomment to move backups to local partition
# MoveToLocal="/var/lib/mysql/tmpp"

# If BackupType is 1 or 3, uncomment to only dunp the schema and NO data. Mostly used for testing
# NoData="--no-data"

########################################## NOTHING TO MODIFY BELOW THIS LINE ###################################

# Set the time so we can know how long this ran
TIME1=`date +%s`
TIME2=`date +%H:%M:%S`
FileDay=`date +%b-%d-%Y`

# Set some other stuff
dateformat='%Y-%m-%d'
hn=`hostname -s`
today=`date +$dateformat`
staledate=`date -d "$keepdays days ago" +$dateformat`
stalepath1="$DIR1/$staledate/" #Files
stalepath2="$DIR2/$staledate/" #SQL Dumps
MySQLDumpErrorLog2="$DIR2/$today/$MySQLDumpErrorLog"


# Set Master Data if this is a master
if [ "$IsMaster" -eq "1" ]
then
	MMD="--master-data=2"
fi

# Set the Lock Command if enabled
if [ "`echo $AllDatabases | grep true`" ] && [ "`echo $LockAll | grep true`" ]
then
	LAT="--lock-all-tables"
fi


function CheckVariables() {

	# Lets check to see if all of the important variables have been set
	if [ -z "$BackupLocation" ] 
	then
		ErrorMessage="The \$BackupLocation variable needs to be set."
		GoodBye=1; ExitAndError
	fi
	
	# Set the MySQL Data Directory
	# MySQL_Data_Dir=`mysql —u $MyUsername —p$MyPassword -Bse "SHOW VARIABLES LIKE '%datadir%'" | awk '{ print $2 }'`
	# Just listing another way to grab... cut or awk. Pick your poisin
	MySQL_Data_Dir=`mysql -u $MyUsername -p$MyPassword -Bse "SHOW VARIABLES LIKE '%datadir%'" | cut -f2`
	MySQL_Data_Dir_Name_Only=`echo $MySQL_Data_Dir | cut -f2 | awk -F/ '{print $(NF-1)}'`

	# Now let's Check to make sure it's not NULL
	if [ -z "$MySQL_Data_Dir" ]
	then
		ErrorMessage="The \$MySQL_Data_Dir variable could not be extracted."
		GoodBye=1; ExitAndError
	fi

	# MySQL Startup and Shutdown Command
	if [ -z "$MySQL_StartupCMD" ] && [ "$IncludeDataDir" ]
	then
		ErrorMessage="The \$MySQL_StartupCMD variable needs to be set."
		GoodBye=1; ExitAndError
	fi

	if [ -z "$MySQL_ShutdownCMD" ] && [ "$IncludeDataDir" ]
	then
		ErrorMessage="The \$MySQL_ShutdownCMD variable needs to be set."
		GoodBye=1; ExitAndError
	fi

	# MySQL Base Dir
	if [ -z "$MySQLBaseDir" ]
	then
		ErrorMessage="The \$MySQLBaseDir variable needs to be set."
		GoodBye=1; ExitAndError
	fi
}

function CheckLock() {

	# If the lock file exists, this script is probably running
	if [ -f $lock_file ]
	then

		# Lets do some redundancy checks to see just how long this has been running
		# If it's been running for too long, delete the lock_file and continue

		current_file=`find $lock_file -cmin -$max_runtime`

		if [ -n "$current_file" ]
		then

			ErrorMessage="This script appears to already be running. Lock file Found ($lock_file)."
			GoodBye=1; ExitAndError
		else
			# echo "Expired lock File found"
			touch $lock_file
		fi

	else # touch the lock file and continue

		touch $lock_file
	fi
}

function IsMySqlAlive() {

	MyAlive=`mysqladmin -u $MyUsername -p$MyPassword ping`

	if [ "`echo $MyAlive | grep alive`" ]
	then
		return 1
	else
		ErrorMessage="MySQL isn't running or improper authentication credentials supplied"
		GoodBye=1; ExitAndError
	fi
}

function IsReplicationRunning() {

	Slave_IO_Running=`mysql -u $MyUsername -p$MyPassword -Bse "show slave status\G" | grep Slave_IO_Running | awk '{ print $2 }'`
	Slave_SQL_Running=`mysql -u $MyUsername -p$MyPassword -Bse "show slave status\G" | grep Slave_SQL_Running | awk '{ print $2 }'`

	if [ "`echo $Slave_IO_Running | grep Yes`" ] && [ "`echo $Slave_SQL_Running | grep Yes`" ]
	then
		return 1;
	else
		ErrorMessage="Slave IO or SQL is not running"
		GoodBye=1; ExitAndError
		# if [ "$?" != "1" ] # I put this here so I can remember it when I need to get the return outside of the function
	fi
}

function IsReplicationBehind() {

	SlaveSlowness=`mysql -u $MyUsername -p$MyPassword -Bse "show slave status\G" | grep Seconds_Behind_Master | awk '{ print $2 }'`

	if [ "$SlaveSlowness" -gt "3600" ]
	then
		ErrorMessage="Slave is one (1) hour or more behind"
		ExitAndError
	fi
}

function CheckDir() {

	# Does the directory exist ?
	if [ -d "$DIR1" ]
	then
		echo "Null" > /dev/null
	
	else # lets create it

		if mkdir SDIR1
		then # good
			echo "Null" > /dev/null
		else # bad
			ErrorMessage="Could not mkdir $DIR1. Check permissions and/or Backup Setting"
			GoodBye=1; ExitAndError
			return 1
		fi
	fi

	# Does the other directory exist ?
	if [ -d "$DIR2" ]
	then
		echo "Null" > /dev/null
	else # lets create it
		
		if mkdir $DIR2
		then # good
			echo "Null" > /dev/null
		else # bad
			ErrorMessage="Could not mkdir $DIR2. Check permissions and/or Backup Setting"
			GoodBye=1; ExitAndError
			return 1
		fi
	fi

	# Does the other directory exist ?
        if [ -d "$DIR3" ]
        then
                echo "Null" > /dev/null
        else # lets create it

                if mkdir $DIR3
                then # good
                        echo "Null" > /dev/null
                else # bad
                        ErrorMessage="Could not mkdir $DIR3. Check permissions and/or Backup Setting"
                        GoodBye=1; ExitAndError
                        return 1
                fi
        fi

	# Check to binlog location if enabled and if so, check its location
	if [ "$IncludeBinLogFiles" ]
	then
		if [ -d "$IncludeBinLogFiles" ]
        	then
                	echo "Null" > /dev/null
		else
			ErrorMessage="MySQL binary log location could not be found in $IncludeBinLogFiles"
			GoodBye=1; GoodBye=1; ExitAndError
		fi
	fi

	# Check to local copy location if enabled and if so, check its location
        if [ "$MoveToLocal" ]
        then    
                if [ -d "$MoveToLocal" ]
                then
                        echo "Null" > /dev/null
                else
                        ErrorMessage="Could not find $MoveToLocal"
                        GoodBye=1; ExitAndError
                fi
        fi
}

function CheckRoot() {

        if [ "`whoami | grep root`" ]
        then
                echo "Null" > /dev/null
        else
                ErrorMessage="You've must execute $0 as root"
                GoodBye=1; ExitAndError
        fi
}

function AreFilesWritable() {

	# In the future, you may have to use "if [ -w "$BackupLog" ] (meaning, is it writable)
	# For now, it's assumed that we're running this as root, so we'll just ask if the file exists with -a

	if [ -a "$BackupLog" ]
	then
		echo "Null" > /dev/null
	else
		# Touch and recheck
		touch $BackupLog
		if [ -a "$BackupLog" ]
		then
			echo "Null" > /dev/null
		else
			ErrorMessage="Could not write to $BackupLog"
			GoodBye=1; ExitAndError
		fi
	fi

	if [ -a "$BackupErrorLog" ]
	then
		echo "Null" > /dev/null
	else
		# Touch and recheck
		touch $BackupErrorLog

		if [ -a "$BackupErrorLog" ]
		then
			echo "Null" > /dev/null
		else
			ErrorMessage="Could not write to $BackupErrorLog"
			GoodBye=1; ExitAndError
	mysqladmin -u $MyUsername -p$MyPassword stop-slave
		fi
	fi
}


function BinLogFileCopy()
{
	# Check the tmpdir location
	#if [ -d "$DIR3/$today" ]
        #then
        #        echo "Null" > /dev/null
        #else
	#	WAWtext="Making Dir $DIR3/$today"; WAWD
        #        mkdir $DIR3/$today
        # fi

	# Don't Continue if we can't get the master log file
	WAWtext="Checking mysql master status"; WAWD
	if [ "`mysql -u $MyUsername -p$MyPassword -e "show master status" | cut -f1 | grep File`" ]
	then
		echo "Null" > /dev/null
	else
		ErrorMessage="Could not get master status"
                GoodBye=1; ExitAndError
	fi

	# Flush Logs
	WAWtext="Flushing binary logs"; WAWD
	mysql -u $MyUsername -p$MyPassword -Bse "flush logs"

	# Get binlog position. We won't tar this.
	master_binlog=`mysql -u $MyUsername -p$MyPassword -Bse "show master status" | cut -f1`
	WAWtext="Current binary log is $master_binlog"; WAWD

	# Change directories
	cd $IncludeBinLogFiles
	if [ "$?" -eq "1" ]
        then
                ErrorMessage="Couldn't cd to $IncludeBinLogFiles"
                Error=1; ExitAndError
	fi

	# Tar everything except for the current file
	WAWtext="Taring BinaryLogs-$FileDay.tar.gz"; WAWD
	# tar cvfz test2.tar.gz `mysql -u root -Bse "show master logs" | cut -f1 | tr '\n' ' ' | sed 's/$master_binlog//g'` >& /dev/null
	tar cfz BinaryLogs-$FileDay.tar.gz `mysql -u $MyUsername -p$MyPassword -Bse "show master logs" | cut -f1 | tr '\n' ' ' | sed "s/$master_binlog//g"`

	# Move to Backup Location
	WAWtext="Moving BinaryLogs-$FileDay.tar.gz to $DIR3"; WAWD
	mv BinaryLogs-$FileDay.tar.gz $DIR3

	# Copy to a local partition?
        if [ "$MoveToLocal" ]
        then
		
		# Delete Files older than 1 day
                WAWtext="Deleting all files from $MoveToLocal older than 1 day"; WAWD
                find $MoveToLocal/* -mtime +1 -exec rm {} \;
		
                WAWtext="Copying $DIR3/*.* to $MoveToLocal"; WAWD
                cp $DIR3/* $MoveToLocal

		if [ "$?" -eq "1" ]
        	then
	                ErrorMessage="Error on cp $DIR3/* $MoveToLocal"
        	        GoodBye=1; ExitAndError
        	fi
        fi

	# Shaun's Note: Keeping this aroung because it's damn good code. It rsync's the binary logs.
	# It's a space killer so we're going for another method (above)

	# Set Copy Status
        #copy_status=0
	
	#for b in `mysql -u $MyUsername -p$MyPassword -Bse "show master logs" | cut -f1`
	#do
		# Grab the name of the log
		#if [ -z $old_log ]
		#then
		#	old_log=$b
		#fi

		# Continue as long as the file isn't on the current log
		#if [ $b != $master_binlog ]
		#then

			#WAWtext="Copying binary log ${b} to $TMPDIR/binlogs"; WAWD
			#rsync -a $IncludeBinLogFiles/$b $TMPDIR/binlogs >& /dev/null

			# Make sure the last rsync copied successfully
			#if [ $? -ne 0 ]
			#then
			#	ErrorMessage="Failed to rsync ${b} to $TMPDIR/binlogs $IncludeBinLogFiles cleanly"
                        #	ExitAndError; copy_status=1
			#	break
			#fi
		#fi				
	#done
}


function MySQLFileCopy()
{
	# To copy the file structure of the mysql directory, we'll need to stop mysql
	# Let's Make Our Output Directory
	# Does the directory exist ?
	if [ -d "$DIR1/$today" ]
        then
               	echo "Null" > /dev/null
	else
		WAWtext="Making Dir $DIR1/$today"; WAWD
		mkdir $DIR1/$today
	fi

	# We only need to do this if this is a slave AND the option to copy the data dir has been enabled
	if [ "$IsMaster" ] && [ "$IsMaster" -eq "2" ] && [ "`echo $IncludeDataDir | grep true`" ]
	then
		# Stop the slave
		WAWtext="Stopping the MySQL slave"; WAWD
		mysqladmin -u $MyUsername -p$MyPassword stop-slave
	fi

	# Only shutdown if we're grabbing the data directory
	if [ "`echo $IncludeDataDir | grep true`" ]
	then
		# Shutdown MySQL
		WAWtext="Shutting down MySQL"; WAWD
		$MySQL_ShutdownCMD

		# Now tar it
		cd $MySQL_Data_Dir../
		WAWtext="Taring $MySQL_Data_Dir to data-$FileDay.tar.gz"; WAWD
                tar cfz data-$FileDay.tar.gz $MySQL_Data_Dir_Name_Only

		# Move file to finel location 
		WAWtext="Moving data-$FileDay.tar.gz to $TMPDIR"; WAWD
		mv data-$FileDay.tar.gz $DIR1/$today
	fi

	# We can restart MySQL Now that we have the data files
	if [ "`echo $IncludeDataDir | grep true`" ]
        then
		WAWtext="Restarting MySQL"; WAWD
     		$MySQL_StartupCMD

		# Check to see if it failed
		if [ "$?" -eq "1" ]
		then
			ErrorMessage="MySQL did not restart after file copy on `hostname`"
			Error=1; ExitAndError
		else
			MyAlive=`mysqladmin -u $MyUsername -p$MyPassword ping`
			WAWtext="$MyAlive"; WAWD			
		fi
	fi

	# If this is a slave, restart it
	if [ "$IsMaster" ] && [ "$IsMaster" -eq "2" ] && [ "`echo $IncludeDataDir | grep true`" ]	
	then
		# Restart the Slave 
                WAWtext="Restarting the MySQL slave"; WAWD
                mysqladmin -u $MyUsername -p$MyPassword start-slave
		
		# Check to see if it failed
                if [ "$?" -eq "1" ]
                then
                        ErrorMessage="MySQL Slave did not start after file copy on `hostname`"
                        Error=1; ExitAndError
                fi
	fi

	# Now let's tar the Files
	cd $MySQLBaseDir 
		
	for j in "${MySQLBackupTheseDirs[@]}"
	do
		# We can't create tar files with '/''s in them. So we need to make sure they are replaced
		filename=`echo $j | sed 's/\//\-/g'`
		WAWtext="Taring $MySQLBaseDir/$j.tar.gz"; WAWD
		tar cfz $filename-$FileDay.tar.gz $j
	done

	# Move .gz files to final location
	WAWtext="Moving $MySQLBaseDir/*.gz to $DIR1/$today"; WAWD
	mv *.gz $DIR1/$today

	# Change Ownership
        if [ "$backupowner" ]
        then
               	WAWtext="Changing ownership to Sbackupowner on $DIR1/$today/*.gz"; WAWD
                chown $backupowner $DIR1/$today/*.*
        fi

	# Copy to a local partition?
	if [ "$MoveToLocal" ]
	then
		# Delete Files older than 1 day
                WAWtext="Deleting all files from $MoveToLocal older than 1 day"; WAWD
                find $MoveToLocal/* -mtime +1 -exec rm {} \;

		WAWtext="Copying $DIR1/$today/*.* to $MoveToLocal"; WAWD
		cp $DIR1/$today/* $MoveToLocal

		if [ "$?" -eq "1" ]
                then
                        ErrorMessage="Error on cp $DIR1/$today/* to $MoveToLocal"
                        GoodBye=1; ExitAndError
                fi		
	fi

	# Remove Stale Dirs
	WAWtext="Removing old stale path (if it exists) $stalepath1"; WAWD
	rm -Rf $stalepath1

	# Don't Continue if there is a problem
	if [ "$Error" ] && [ "$Error" -eq "1" ]
	then
		ErrorMessage="Quitting backup due to previous errors"
		GoodBye=1; ExitAndError
	fi
}
 

function MySQLBackupDump()
{
	# Make output directory if it doesnt the directory exist ?
        if [ -d "$DIR2/$today" ]
        then
                echo "Null" > /dev/null
        else
		WAWtext="Making Dir $DIR2/$today"; WAWD
                mkdir $DIR2/$today
        fi		
	
	# change directories
	cd $DIR2/$today

	# Are we dumping individual databases?
	if [ "$databases" ]
	then
		for i in "${databases[@]}"
		do
			# We have to use a different mysql dump for the mysql database
			if [ "`echo $i | grep mysql`" ]
			then
				WAWtext="Creating MySQLDump of $i in $DIR2/$today"; WAWD
				mysqldump -u $MyUsername -p$MyPassword $NoData --skip-lock-tables --routines --triggers --comments --log-error=$MySQLDumpErrorLog2 $i > $i-$FileDay.sql
			else
				WAWtext="Creating MySQLDump of $i in $DIR2/$today"; WAWD
				mysqldump -u $MyUsername -p$MyPassword $NoData --opt  --flush-logs --routines --triggers --comments --log-error=$MySQLDumpErrorLog2 $i | gzip > $i-$FileDay.sql.gz
			fi
		done
	fi 

	# Are we grabbing all databases into one file ?
	if [ "$AllDatabases" ]
	then
		WAWtext="Creating MySQLDump of ALL DATABASES in $DIR2/$today"; WAWD
		mysqldump --all-databases -u $MyUsername -p$MyPassword $NoData --opt $MMD $LAT --flush-logs --routines --triggers --comments --log-error=$MySQLDumpErrorLog2 | gzip > FullMysqlDump-$FileDay.sql.gz
	fi

	# Change Ownership
        if [ "$backupowner" ]
        then
                WAWtext="Changing ownership to $backupowner on $DIR2/$today/*.*"; WAWD
                chown $backupowner $DIR2/$today *.*
        fi

	# Copy to a local partition?
        if [ "$MoveToLocal" ]
        then
		# Delete Files older than 1 day
                WAWtext="Deleting all files from $MoveToLocal older than 1 day"; WAWD
                find $MoveToLocal/* -mtime +1 -exec rm {} \;

                WAWtext="Copying $DIR2/$today/*.* to $MoveToLocal"; WAWD
                cp $DIR2/$today/* $MoveToLocal

		if [ "$?" -eq "1" ]
                then
                        ErrorMessage="Error on cp $DIR2/$today/* to $MoveToLocal"
                        GoodBye=1; ExitAndError
                fi
        fi

	# Remove Stale Dirs
	WAWtext="Removing old stale path (if it exists) $stalepath2"; WAWD
        rm -Rf $stalepath2
}


function WAWD() {

        # W.A.W.D. = What are we doing?
        # This function simply echos what we are doing to the screen and log. This saves lines

        echo "`date` `hostname` $WAWtext" >> $BackupLog
        echo "`date` $WAWtext"
}


function ExitAndError() {

        # Print Problem to Log
        echo "`date` `hostname` Error: $ErrorMessage" >> $BackupErrorLog

        # Tell the BackupLog file we had a problem
        echo "`date` `hostname` [ERROR] See $BackupErrorLog for details" >> $BackupLog

        # Dump to syslog
        Error_IO="MySQL Backup Error: $ErrorMessage. See $0"
        logger -s -p 3 $Error_IO

        # Echo Problem to Screen
        echo -e "\nError: $ErrorMessage\n"

        # Email Alert
        echo $Error_IO | mail -s "[MySQL BACKUP ALERT] - MySQL backup on `hostname` has a problem. See $0" $EmailNotify

        # Remove the Lock File
        rm -Rf $lock_File

        # Exit the Script if flagged
	if [ "$GoodBye" -eq "1" ]
	then
        	exit 10
	fi
}

######### LETS BEGIN ########


# We're starting
WAWtext="**START Backup Routine**"; WAWD

# Begin Checks
WAWtext="STEP 1: Begin Checks -----"; WAWD

	# Run only as root?
	if [ "$RunAsRoot" ]
	then
		WAWtext="Checking to see if we are root"; WAWD
		CheckRoot
		WAWtext="Ok"; WAWD
	fi

	# Check that all variables are set
	WAWtext="Checking to see if variables are set"; WAWD
	CheckVariables
	WAWtext="Ok"; WAWD

	# Check to see if log files are writable
	WAWtext="Checking to see if necessary files are writable"; WAWD
	AreFilesWritable
	WAWtext="Ok"; WAWD

	# Check to see if backup directories exist
	WAWtext="Checking to see if necessary directories exist and are writable"; WAWD
	CheckDir
	WAWtext="Ok"; WAWD

	# Is MySQL Alive?
	WAWtext="Checking to see if MySQL is alive"; WAWD
	IsMySqlAlive
	WAWtext="Ok"; WAWD

	if [ "$IsMaster" ] && [ "$IsMaster" -eq "2" ]
	then
		# Check to see if the dbdump slave is running and up to date. If not, exit
		WAWtext="Checking to see if MySQL replication is running"; WAWD
		IsReplicationRunning
		WAWtext="Ok"; WAWD

		# Check to see if replication is behind too Far. IF yes, exit cause nobody wants an old backup
		WAWtext="Checking to see if MySQL replication is 1 hour or more behind"; WAWD
		IsReplicationBehind
		WAWtext="Ok"; WAWD
	fi

	# Set Lock File and Continue
	WAWtext="Checking and setting locks"; WAWD
	CheckLock
	WAWtext="Ok"; WAWD
	WAWtext="All check verified ok. OK to begin."; WAWD

# FILE COPY - Only do this if the $BackupType is 2 (file copy only) or 3 (sqldump)
if [ "$BackupType" -eq "2" ] || [ "$BackupType" -eq "3" ]
then
	# Dump some files
	WAWtext="STEP 2: Time to Copy and Tar some files -----"; WAWD
	MySQLFileCopy
	WAWtext="STEP 2: Done"; WAWD
else
	# Echo Skip
        WAWtext="STEP 2: Skipping TAR and File Copy"; WAWD
fi

# MySQL Dump - Only do this if the $BackupType is 1 or 3
if [ "$BackupType" -eq "1" ] || [ "$BackupType" -eq "3" ]
then
	WAWtext="STEP 3: MySQL Dump -----"; WAWD
	MySQLBackupDump
	WAWtext="STEP 3: Done"; WAWD
else
	WAWtext="STEP 3: Skipping MySQL Dump"; WAWD
fi

# Copy Binary Log Files
if [ "$IncludeBinLogFiles" ]
then
	WAWtext="STEP 4: Copy and archive  binlogs -----"; WAWD
	BinLogFileCopy
	WAWtext="STEP 4: Done"; WAWD
else
	WAWtext="STEP 4: Skipping binlog copy"; WAWD
fi

# Remove the lock file
WAWtext="STEP 5: Removing Lock File -----"; WAWD
rm $lock_file


# We're done
TIME2=`date +%s`
elapsed_time=$(( ( $TIME2 - $TIME1 ) / 60 ))
elapsed_time_seconds=$(( ( $TIME2 - $TIME1 ) ))
WAWtext="**FINISHED Backup Routine. Total elapsed time: $elapsed_time minutes $elapsed_time_seconds seconds**"; WAWD
echo "" >> $BackupLog
exit 0
