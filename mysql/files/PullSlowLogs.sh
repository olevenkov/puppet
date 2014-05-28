#!/bin/bash

####
## This file is managed by puppet, do not change it locally.
##

shout() { echo "$0: $*" >&2; }
barf() { shout "$*"; exit 128; }
safe() { "$@" || barf "can not $*"; }

######### SCRIPT CONFIGURATION ########
#
# Source SSH user
SourceSshUser="root"

# Backup Log Name
PullLog="/var/lib/mysql/scripts/pull.log"

# Set location of lock file
lock_file="/var/lib/mysql/scripts/Pull-In-Progress.lck"

# Max Runtime in minutes
max_runtime=360 # (6 hours)

# Send Email to on error
EmailNotify="o.levenkov@us.nature.com"

########################################## NOTHING TO MODIFY BELOW THIS LINE ###################################

# Grab some variables if not set
if [ -z $1 ]
then
        echo -n "Source IP >> "
        read SourceIP
else
        SourceIP=$1
fi

if [ -z $2 ]
then
        echo -n "Source File(s) (include full path) >> "
        read SourceFiles
else
        SourceFiles=$2
fi

if [ -z $3 ]
then
        echo -n "Target Dir (full path) >> "
        read TargetDir
else
        TargetDir=$3
fi

# Set the time so we can know how long this ran
TIME1=`date +%s`
TIME2=`date +%H:%M:%S`
FileDay=`date +%b-%d-%Y`

# Set some other stuff
dateformat='%Y-%m-%d'
hn=`hostname -s`
today=`date +$dateformat`

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
			GoodBye=1; ReportError
		else
			# echo "Expired lock File found"
			touch $lock_file
		fi

	else # touch the lock file and continue

		touch $lock_file
	fi
}

function AreFilesWritable() {

	if [ -a "$PullLog" ]
	then
		echo "Null" > /dev/null
	else
		# Touch and recheck
		touch $PullLog
		if [ -a "$PullLog" ]
		then
			echo "Null" > /dev/null
		else
			ErrorMessage="Could not write to $PullLog"
			GoodBye=1; ReportError
		fi
	fi
}

function WAWD() {

        # W.A.W.D. = What are we doing?
        # This function simply echos what we are doing to the screen and log. This saves lines

        echo -e "`date` $0: $WAWtext" >> $PullLog
        echo -e "`date` $0: $WAWtext"
}


function ReportError() {

        # Tell the BackupLog file we had a problem
        echo "`date` $0: [ERROR] $ErrorMessage" >> $PullLog

        # Dump to syslog
        Error_IO="$0 Error: $ErrorMessage. See $0"
        logger -s -p 3 $Error_IO

        # Echo Problem to Screen
        echo -e "\nError: $ErrorMessage\n"

        # Email Alert
        echo $Error_IO | mail -s "$0 on `hostname` has a problem: $ErrorMessage" $EmailNotify

        # Remove the Lock File
        rm -Rf $lock_File

        # Exit the Script if flagged
	if [ "$GoodBye" ] && [ "$GoodBye" -eq "1" ]
	then
        	exit 10
	fi
}

######### LETS BEGIN ########


# We're starting
WAWtext="**START Routine**"; WAWD

# Begin Checks
WAWtext="Begin Checks -----"; WAWD

	# Check to see if log files are writable
	WAWtext="Checking to see if necessary files are writable"; WAWD
	AreFilesWritable
	WAWtext="Ok"; WAWD

	# Set Lock File and Continue
	WAWtext="Checking and setting locks"; WAWD
	CheckLock
	WAWtext="Ok"; WAWD
	WAWtext="All checks verified ok. OK to begin."; WAWD

# Start Pulling
WAWtext="scp -p $SourceSshUser@$SourceIP:$SourceFiles $TargetDir"; WAWD
scp -p $SourceSshUser@$SourceIP:$SourceFiles $TargetDir
WAWtext="Done"; WAWD

# Remove the lock file
WAWtext="Removing Lock File -----"; WAWD
rm $lock_file


# We're done
TIME2=`date +%s`
elapsed_time=$(( ( $TIME2 - $TIME1 ) / 60 ))
elapsed_time_seconds=$(( ( $TIME2 - $TIME1 ) ))
WAWtext="**FINISHED Pull. Total elapsed time: $elapsed_time minutes $elapsed_time_seconds seconds**"; WAWD
echo "" >> $PullLog
exit 0
