#!/bin/bash

# MakeMysqlDirectories.sh
#
###### SHOUT BARF SAFE ######
#
shout() { echo "$0: $*" >&2; }
barf() { shout "$*"; exit 128; }
safe() { "$@" || barf "can not $*"; }

# Base MySQL Dir (no trailing slash)
BMD="/var/lib/mysql"

Dirs=( "$BMD/backups" "$BMD/backups/files" "$BMD/backups/logs" "$BMD/backups/sqldumps" "$BMD/data" "$BMD/etc"
       "$BMD/logs" "$BMD/logs/bin" "$BMD/logs/error" "$BMD/logs/relay" "$BMD/logs/slow" "$BMD/scripts" "$BMD/tmp" )


########################################## NOTHING TO MODIFY BELOW THIS LINE ###################################

TIME1=`date +%s`

function CheckRoot() {

        if [ "`whoami | grep root`" ]
        then
                echo "Null" > /dev/null
        else
                ErrorMessage="You've must execute $0 as root"
                GoodBye=1; ExitAndError
        fi
}

function MakeDirs()
{
	# Check to see if basedir exists. If not, cease script
        if [ -d "$BMD" ]
        then
                WAWtext="$BMD exists. Excellent! Continuing."; WAWD

        else
		ErrorMessage="The base MySQL Directory ($BMD) doesn't exist"
                GoodBye=1; ExitAndError
	fi

	# Create /var/run/mysql
	if [ -d "/var/run/mysql" ]
        then
                WAWtext="/var/run/mysql exists. Skipping."; WAWD

        else
		safe mkdir /var/run/mysql
		safe chown mysql.mysql /var/run/mysql
		WAWtext="/var/run/mysql created and ownership changed"; WAWD
        fi

	safe cd $BMD

	# Continue making directories
	for j in "${Dirs[@]}"
        do
		if [ -d "$j" ]
       		then
			WAWtext="$j already exists. Skipping."; WAWD
        	else
                	if mkdir $j
                	then
                		WAWtext="mkdir $j successful."; WAWD

				# Changing Ownership
				if [ "`echo $j | grep logs`" ] || [ "`echo $j | grep data`" ]
				then
					# Dont do $j if it's $BMD/backups/logs
					if [ "`echo $j | grep $BMD/backups/logs`" ]
					then
						echo "Null" > /dev/null
					else
						safe chown mysql.mysql $j
						WAWtext="Ownership of $j changed to mysql.mysql."; WAWD
					fi
				fi
                	else
                        	ErrorMessage="Could not mkdir $j."
                        	GoodBye=1; ExitAndError
                	fi
		fi
	done

	# Change Permissions on a few directories
        WAWtext="Permissions of $BMD/logs/slow AND $BMD/logs/error changed to rwxrwxrwx"; WAWD
        safe chmod -R 777 $BMD/logs/slow
        safe chmod -R 777 $BMD/logs/error
}


function WAWD() {

        # W.A.W.D. = What are we doing?
        echo "`date` $WAWtext"
}

function ExitAndError() {

        # Echo Problem to Screen
        echo -e "\nError: $ErrorMessage\n"

        # Exit the Script if flagged
        if [ "$GoodBye" -eq "1" ]
        then
                exit 10
        fi
}

function AdditionalInstructions()
{
	echo -e ""
	echo -e "*** If setting up or modifying mysql environment, these may help you ***"
	echo -e "1. Set mysql.sock in my.cnf to /var/run/mysql/mysql.sock"
	echo -e "2. Move my.cnf to $BMD/etc:  mv $BMD/my.cnf $BMD/etc"
	echo -e "3. Remove symlink in /etc:  rm /etc/my.cnf"
	echo -e "4. Create new symlink:  cd /etc/; ln -s $BMD/my.cnf my.cnf; cd $BMD"
	echo -e "5. Move Binary Files (if applicable):  mv $BMD/mysql-bin* $BMD/logs/bin"
	echo -e "6. Move Relay Files (if applicable):  mv $BMD/mysql-relay* $BMD/logs/relay"
	echo -e "7. Move INNODB files (if applicable):  mv $BMD/ib* $BMD/data"
	echo -e "8. Move mysql data directory and all other database directories to $BMD/data"
	echo -e "9. Move anything that doesn't belong in $BMD to it's rightful place"
	echo -e "10. Don't forget to grab your aliases"
	echo -e "11. Don't forget to set .my.cnf in /root and ~"
	echo -e ""
}

# Check to see if script is executing as root
CheckRoot

# Make the directories
MakeDirs

# We're done
TIME2=`date +%s`
elapsed_time=$(( ( $TIME2 - $TIME1 ) / 60 ))
elapsed_time_seconds=$(( ( $TIME2 - $TIME1 ) ))
# WAWtext="**FINISHED Backup Routine. Total elapsed time: $elapsed_time minutes $elapsed_time_seconds seconds**"; WAWD
WAWtext="Done."; WAWD

# Echo Additional Instructions
AdditionalInstructions

exit 0
