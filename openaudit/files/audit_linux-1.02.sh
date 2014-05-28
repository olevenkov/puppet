#!/bin/bash
###################################
#     Sleep Functions             #
###################################

# convert hex digits to uppercase.
number=`hostid | sed -e 's:^0[bBxX]::' | tr '[a-f]' '[A-F]'`

# convert hex to decimal
dec=`echo "ibase=16; $number" | bc`

# sleep a random amount of time, no more than 10 minutes.
delay=$(($dec % 600))
echo "Sleeping for $delay seconds"
sleep $delay

###################################
#     Define Script Functions     #
###################################
#-Functions_Start-#
OA_Usage() {
  echo ""
  echo "Usage: $0 [options] ..."
  echo ""
  echo "This script audits Linux or Windows machines and submits the results to Open-AudIT."
  echo ""
  echo "Options:"
  echo "  -h              Show this information and exit"
  echo "  -v              Print the version and exit"
  echo "  -n              Run the script without requiring root priveleges"
  echo "  -w <unc path>   Windows audit. UNC path to audit.vbs (Ex. //server/share/audit.vbs)"
  echo "  -b <basedn>     basedn for domain audits (Ex. \"ou=servers,dc=domain,dc=com\")"
  echo "  -c <path>       Change the path to the audit.config file (Ex. /home/user/audit.config)"
  echo "  -P <path>       A file with a list of package names to audit (Linux audits)"
  echo "  -l <path>       Change the path to the audit log (Ex. /home/user/audit_domain.csv)"
  echo "  -S              Linux safemode audit (Doesn't search path to determine file locations)"
  echo "  -a              Log audits using syslog (Default: local0.info)"
  echo "  -p <fac.pri>    The facility and priority to use for syslog (Ex. local1.info)"
  echo "  -C <computers>  List of computers to audit (Ex. \"comp1 comp2 comp3 srv1 srv2 srv3\")"
  echo ""
  echo "Common Audits (No audit.config needed):"
  echo "  -L              Local workstation audit (requires the 'o' argument)"
  echo "  -R              Remote workstation audit (Requires the 's' argument)"
  echo "  -D              Domain audit (Requires the 'd','y', and 'H' arguments)"
  echo "  -I              Input audit (Requires the 'i' or 'C' argument)"
  echo ""
  echo "Override audit.config Variables :"
  echo "  -q              Do not be verbose (audit.config - verbose = \"n\")"
  echo "  -H <ldap uri>   ldap_domain variable (Ex. ldap://domain.com)"
  echo "  -s <hostname>   Hostname to audit (strComputer variable)"
  echo "  -i <path>       Path to the input file (Ex. /home/user/input.txt)"
  echo "  -U <web url>    URL to submit to (Ex. http://openaudit/admin_pc_add_2.php)"
  echo "  -o <on|off>     Online or offline audit (online variable)"
  echo "  -t <uuid|mac>   The UUID type (uuid variable)"
  echo "  -N <number>     Number of audits to run simultaneously (number_of_audits variable)"
  echo "  -k              Specify to keep/append the audit log (keep_audit_log variable)"
  echo ""
  echo "Authentication Options:"
  echo "  -A <path>       The path to a samba credentials file for Windows audits"
  echo "  -y <path>       The path to a LDAP password file for the domain account"
  echo "  -d <user>       Domain account for domain audits (Ex. user@domain.com)"
  echo "  -u <user>       Set the SSH user account for remote Linux audits"
  echo ""
  exit
}

OA_Trace() {
  OA_Audit_Log "" "log_trace" "" "$1"
  if [ "$verbose" = "y" ] || [ "$verbose" = "Y" ]; then
    echo $1
  fi
}

OA_Getopt_Check() {
  option="$1"
  argument="$2"
  if echo "$argument" | grep -qE '^-'; then
    echo ""
    echo "'-${option}' option used without argument"
    OA_Usage
  fi
}

OA_Cleanup() {
  if [ -n "$remote_script" ]; then
    if [ -e "$remote_script" ]; then
      rm -f "$remote_script"
    fi
  fi
  exit
}

OA_Audit_Log() {
  # Define a function to write to file or syslog
  OA_Audit_Write() {
    oa_log_text=$1
    oa_log_timestamp="$($oa_date +%x' '%r),${oa_log_host},"

    if [ -z "$opt_syslog" ]; then
      echo "${oa_log_timestamp}'${oa_log_text}'" >> "$audit_log"
    else
      $oa_logger -p ${opt_syslog_facility-"local0.info"} -t OpenAudIT "$oa_log_text" 2> /dev/null
    fi
  }

  if [ -n "$opt_syslog" ] || [ "$use_audit_log" = "y" -o "$use_audit_log" = "Y" ]; then
    oa_log_host="$1"
    oa_log_reason="$2"
    oa_log_type="$3"
    oa_log_misc="$4"

    # Use the alternate log file location if specified
    audit_log="${opt_audit_log-"./audit_log.csv"}"


    case $oa_log_reason in
      connect_failed) OA_Audit_Write "Failed Not Available - $oa_log_host";;
      audit_error) OA_Audit_Write "Error Exit Status (${oa_log_misc}) on Audit of $oa_log_host";;
      audit_hang) OA_Audit_Write "Killing Hanging Process for - $oa_log_host";;
      audit_start) OA_Audit_Write "Starting Audit of $oa_log_host";;
      audit_success) OA_Audit_Write "Audit Result - $oa_log_host - Completed OK";;
      scp_error) OA_Audit_Write "Error Copying Script to $oa_log_host";;
      log_trace) OA_Audit_Write "$oa_log_misc";;
      log_end)
        oa_elapsed_time=$oa_log_misc
        oa_elapsed_time_fmt=$($oa_date -d "00:00:00 $oa_elapsed_time seconds" +%Hh%Mm%Ss)
        OA_Audit_Write "Audit Script Complete. Elapsed time of script - $oa_elapsed_time seconds (${oa_elapsed_time_fmt})"
	;;
      log_header) 
        if [ -z "$opt_syslog" ]; then
          if [ "$keep_audit_log" = "y" ] || [ "$keep_audit_log" = "Y" ]; then
            echo "TIME,MACHINE,RESULT" >> "$audit_log"
          else
            echo "TIME,MACHINE,RESULT" > "$audit_log"
          fi
        fi
	;;
      log_start_success) 
        if [ "$oa_log_type" = "ldap" ]; then
          for ldap_host in $(echo "$oa_log_misc" | $oa_awk '{print $0}'); do
            oa_log_timestamp="$($oa_date +%x' '%r),${oa_log_host},"
            OA_Audit_Write "Audit Result - Computer Name from ldap: $ldap_host - Completed OK."
          done
	else
          OA_Audit_Write "Audit Result - File $input_file read into variable. - Completed OK."
          OA_Audit_Write "Audit Result - Number of systems retrieved from file: $oa_log_misc - Completed OK."
        fi
	;;
      log_start_failed)
        if [ "$oa_log_type" = "ldap" ]; then
          OA_Audit_Write "LDAP Query for - $local_domain - Failed"
        else
          OA_Audit_Write "Reading Input File -  $input_file - Failed."
        fi
	;;
    esac
  fi
}

OA_Remote_Lin_Audit() {
  # remote_script_path : Tmp location of the script on the remote machine
  linux_hostname="$1"
  remote_user="$2"
  remote_script_path="/tmp/${remote_script_name}"

  #  If this is an input file or ldap audit, then the file will
  #+ already exist, don't want to overwrite it ...
  if [ ! -e "$remote_script" ]; then
    # Put the pieces of the script together that will go on the remote machine.
    echo "#!/bin/bash" > "$remote_script"
    $oa_sed -n '/^#-Functions_Start-#/,/^#-Functions_End-#/p' $0 >> "$remote_script"
    $oa_sed -n '/^#-Variables_Start-#/,/^#-Variables_End-#/p' $0 >> "$remote_script"
    echo "audit_host=$audit_host" >> "$remote_script"
    echo "uuid=$uuid" >> "$remote_script"
    echo "verbose=$verbose" >> "$remote_script"
    echo "non_ie_page=$non_ie_page" >> "$remote_script"
    echo "online=yesxml" >> "$remote_script"
    echo "software_audit=$software_audit" >> "$remote_script"

    $oa_sed -n '/^#-SSH_AUDIT_SCRIPT-#/,$p' $0 >> "$remote_script"
    chmod 755 "$remote_script"
  fi

  #  Basic connectivity test. This will fail though if the machine is
  #+ firewalled in a reasonable way. Perhaps also add a test for port
  #+ 22 using netcat? This could also fail if using a non-standard
  #+ port though. Perhaps an optional argument for a port number?
  if ping -c 3 "$linux_hostname" > /dev/null 2>&1; then
    OA_Audit_Log "$linux_hostname" "audit_start"
    OA_Trace "---------------------------------------------"
    OA_Trace "(Linux) Starting audit of  - $linux_hostname -"
    OA_Trace "---------------------------------------------"

    # Copy the script to the remote machine and run it.
    $oa_scp "$remote_script" "$remote_user"@"$linux_hostname":"$remote_script_path"
    if [[ $? -ne 0 ]]; then
      OA_Audit_Log "$linux_hostname" "scp_error"
    else
      $oa_ssh "$remote_user"@"$linux_hostname" "$remote_script_path"
      if [[ $? -ne 0 ]]; then
        OA_Audit_Log "$linux_hostname" "audit_error" "" "$?"
      else
        OA_Audit_Log "$linux_hostname" "audit_success"
      fi
      # Delete the script sent to the remote machine.
      $oa_ssh "$remote_user"@"$linux_hostname" /bin/rm "$remote_script_path"
    fi
  else
    OA_Audit_Log "$linux_hostname" "connect_failed"
    OA_Trace "-----------------------------------------------"
    OA_Trace "(Linux) Unable to connect to : $linux_hostname"
    OA_Trace "-----------------------------------------------"
    OA_Trace ""
  fi
}

OA_Remote_Win_Audit() {
  windows_hostname="$1"
  if ping -c 3 "$windows_hostname" > /dev/null 2>&1; then
    OA_Audit_Log "$windows_hostname" "audit_start"
    OA_Trace "-----------------------------------------------"
    OA_Trace "(Windows) Starting audit of : $windows_hostname -"
    OA_Trace "-----------------------------------------------"
    OA_Trace ""
    $oa_winexe --uninstall -A $opt_smb_credentials //$windows_hostname "cscript $opt_unc_path"
    windows_error_code=$?
    if [[ $windows_error_code -ne 0 ]]; then
      OA_Audit_Log "$windows_hostname" "audit_error" "" "$windows_error_code"
    else
      OA_Audit_Log "$windows_hostname" "audit_success"
    fi
  else
    OA_Audit_Log "$windows_hostname" "connect_failed"
    OA_Trace "-----------------------------------------------"
    OA_Trace "(Windows) Unable to connect to : $windows_hostname"
    OA_Trace "-----------------------------------------------"
    OA_Trace ""
  fi
}

OA_Process_Audits() {
  process_os="$2"
  process_type="$3"
  computer_list="$1"
  computers_processed=0
  computer_count=$(echo "$computer_list" | wc -l)
  echo "Comp List:"
  echo "$computer_list"

  for remote_hostname in $(echo "$computer_list" | $oa_awk '{print $0}'); do
    computers_remaining=$($oa_expr $computer_count - $computers_processed)
    computers_processed=$($oa_expr $computers_processed + 1)

    # The number of audits we want are already running, so wait.
    while [[ "$(jobs -pr | wc -l)" -ge "$number_of_audits" ]]; do 
      OA_Trace "-----------------------------------------------"
      OA_Trace "Number of Audits Running: $(jobs -pr | wc -l)"
      OA_Trace "Number of Audits Left: $computers_remaining"
      OA_Trace "Sleeping For a Bit Before Continuing ..."
      OA_Trace "-----------------------------------------------"
      sleep 5s
      # Kill child processes running longer than the value of script_timeout in minutes
      for oa_child_pid in $(jobs -pr); do
        # Grab the time for the PID in minutes
        oa_child_time=$($oa_date -d $(ps -p $oa_child_pid -o etime --no-headers) +%H 2> /dev/null | $oa_sed 's/^0//')
        if [ -n "$oa_child_time" ] && [[ "$oa_child_time" -ge "$script_timeout" ]]; then
          oa_child_hostname=$(echo "$hostname_pid" | $oa_awk 'BEGIN{RS = " "; FS = "\n"}; /^'"$oa_child_pid"'/{split($0,a,","); print a[2]}')
          OA_Audit_Log "$oa_child_hostname" "audit_hang"
          OA_Trace "-----------------------------------------------"
          OA_Trace "Killing Hanging Child Process : $oa_child_hostname -"
          OA_Trace "-----------------------------------------------"
          kill -9 $oa_child_pid
        fi
      done
    done

    # Add another job if the number of audits isn't met yet.
    if [[ "$(jobs -pr | wc -l)" -lt "$number_of_audits" ]]; then
      OA_Trace "-----------------------------------------------"
      OA_Trace "Starting Child Process For - $remote_hostname -"
      OA_Trace "Audit Number $computers_processed of $computer_count"
      OA_Trace "-----------------------------------------------"
      if [ "$process_os" = "windows" ]; then
        OA_Remote_Win_Audit "$remote_hostname" > /dev/null 2>&1 &
      else
        #  Check for specific usernames in the input file. If found, set them as the
        #+ variables, otherwise use the username from script parameter.
        if [ "$($oa_awk -F, '/^'"$remote_hostname"'/{print $2}')" ] && [ "$process_type" = "input_file" ]; then
          remote_ssh_user=$($oa_awk -F, '/^'"$remote_hostname"'/{print $2}')
        else
          remote_ssh_user=$opt_ssh_user
        fi
        remote_script="/tmp/audit_linux_ssh.$$"
        OA_Remote_Lin_Audit "$remote_hostname" "$remote_ssh_user" > /dev/null 2>&1 &
      fi
      # Track PID by hostname and job ID for logging hung processes
      child_job=$(jobs %% | $oa_awk '{print $1}' | $oa_sed 's/[^0-9]//g')
      hostname_pid="${hostname_pid}$!,${remote_hostname},${child_job} "
    fi 

    # If the last computer has been processed, then wait for audits to finish.
    if [[ "$computers_processed" -eq "$computer_count" ]]; then
      while [[ "$(jobs -lr | wc -l)" -gt "0" ]]; do
        OA_Trace "-----------------------------------------------"
        OA_Trace "Number of Audits Running: $(jobs -pr | wc -l)"
        OA_Trace "Waiting for Running Audits to Finish ..."
        OA_Trace "-----------------------------------------------"
        sleep 5s
        # Kill child processes running longer than or equal to $script_timeout
        for oa_child_pid in $(jobs -pr); do
          # Grab the time for the PID in minutes
          oa_child_time=$($oa_date -d $(ps -p $oa_child_pid -o etime --no-headers) +%H 2> /dev/null | $oa_sed 's/^0//')
          if [ -n "$oa_child_time" ] && [[ "$oa_child_time" -ge "$script_timeout" ]]; then
          oa_child_hostname=$(echo "$hostname_pid" | $oa_awk 'BEGIN{RS = " "; FS = "\n"}; /^'"$oa_child_pid"'/{split($0,a,","); print a[2]}')
          oa_child_jobid=$(echo "$hostname_pid" | $oa_awk 'BEGIN{RS = " "; FS = "\n"}; /^'"$oa_child_pid"'/{split($0,a,","); print a[3]}')
            OA_Audit_Log "$oa_child_hostname" "audit_hang"
            OA_Trace "-----------------------------------------------"
            OA_Trace "Killing Hung Child Process : $oa_child_hostname -"
            OA_Trace "-----------------------------------------------"
            kill -9 $oa_child_pid > /dev/null 2>&1
          fi
        done
      done
    fi
  done
}

OA_LDAP_Audit() {
  if [ -n "$local_domain" ]; then
    OA_Audit_Log "" "log_header"
    #  Adjust the below value if your ldap query fails due to page size limits.
    oa_pr_size=1000
    OA_Trace "Querying LDAP for a list of computers ..."
    oa_ad_computers=$($oa_ldapsearch -x -D $opt_ad_user -y $opt_ad_pass -H $local_domain ${opt_basedn-}-L -E pr=${oa_pr_size}/noprompt "(objectClass=Computer)" cn | $oa_awk '/^cn:/{print $2}')
    #  Make the list random by using the builtin random var and sort, then remove the
    #+ number and quotations with sed.
    oa_ad_computers=$(for i in $(echo "$oa_ad_computers" | $oa_awk '{print $0}'); do \
                      echo "$RANDOM $i"; done | $oa_sort \
                      | $oa_sed 's/\(^\"|\"$\)//g;s/[0-9]\+ //g')
    if [ "$oa_ad_computers" != "" ] && [ -n "$opt_type" ]; then
      OA_Audit_Log "" "log_start_success" "ldap" "$oa_ad_computers"
      OA_Trace "-----------------------------------------------"
      OA_Trace "Processing LDAP Query of : $local_domain"
      OA_Trace "(Windows) Computers to audit: $(echo "$oa_ad_computers" | wc -l)"
      OA_Trace "-----------------------------------------------"
      OA_Process_Audits "$oa_ad_computers" "windows"
    elif [ "$oa_ad_computers" != "" ] && [ -z "$opt_type" ]; then
      OA_Audit_Log "" "log_start_success" "ldap" "$oa_ad_computers"
      OA_Trace "-----------------------------------------------"
      OA_Trace "Processing LDAP Query of : $local_domain"
      OA_Trace "(Linux) Computers to audit: $(echo "$oa_ad_computers" | wc -l)"
      OA_Trace "-----------------------------------------------"
      OA_Process_Audits "$oa_ad_computers" "linux"
    else
      OA_Audit_Log "" "log_start_failed" "ldap"
      echo "No computers returned from LDAP query."
      echo "Check ldap.conf and $config_path for proper settings"
      exit 1
    fi
  else
    echo "local_domain variable not set. Set in audit.config or see usage."
    OA_Usage
  fi
}
#-Functions_End-#
###################################
#          Check Options          #
###################################

#  Modified PATH incase this is run from cron to account for the limited
#+ environment in which cron jobs are run.
if ! tty -s; then
  PATH=${PATH}:/usr/local/bin:/sbin:/usr/sbin
fi

#  getopts is too simplistic, so output usage if user enters --help
#+ or if it appears that the option doesn't start with a dash
if [ "$1" == "--help" ] || $(echo "$1" | grep -qE '^[^-]'); then
  OA_Usage
fi

# Print the version if --version or -v is used
if [ "$1" == "--version" ] || [ "$1" == "-v" ]; then
  echo "1.02"
  exit 0;
fi

# Check arguments with getopts
while getopts hnakqLDIRSb:c:C:d:l:t:w:N:i:p:P:u:s:y:o:A:H:U: options; do
  case $options in
    a)  opt_syslog="yes";;
    A)  if [ ! -e "$OPTARG" ]; then
          echo ""
          echo "The samba credentials file doesn't exist: \"${OPTARG}\""
          echo ""
          exit 1
        fi
        opt_smb_credentials="$OPTARG"
      ;;
    b)  OA_Getopt_Check "$options" "$OPTARG"
        opt_basedn="-b $OPTARG "
      ;;
    c)  if [ ! -e "$OPTARG" ]; then
          echo ""
          echo "The specified config file doesn't exist: \"${OPTARG}\""
          echo ""
          exit 1
        fi
        opt_config_path=$OPTARG
      ;;
    C)  OA_Getopt_Check "$options" "$OPTARG"
        opt_system_list=$OPTARG
      ;;
    d)  OA_Getopt_Check "$options" "$OPTARG"
        opt_ad_user=$OPTARG
      ;;
    D)  opt_audit_domain="yes";;
    h)  OA_Usage;;
    H)  OA_Getopt_Check "$options" "$OPTARG"
        opt_ldap_uri=$OPTARG
      ;;
    i)  if [ ! -e "$OPTARG" ]; then
	  echo ""
          echo "The specified input file doesn't exist: \"${OPTARG}\""
          echo ""
          exit 1
        fi
        opt_input_file=$OPTARG
      ;;
    I)  opt_audit_input="yes";;
    k)  opt_log_append="y";;
    l)  if [ -n "$OPTARG" ] && ! echo "$ARGUMENT" | grep -qE '^-'; then
          if $(touch "$OPTARG"); then
            opt_audit_log="$OPTARG"
          else
            echo ""
            echo "Unable to write to logfile location: \"${OPTARG}\""
            echo ""
            exit 1
          fi
        fi
        opt_log_config="y"
      ;;
    L)  opt_audit_local="yes";;
    n)  opt_root="yes";;
    N)  if echo "$OPTARG" | grep -qE '^[1-9][0-9]?$'; then
          opt_number_audits=$OPTARG
        else
          echo ""
          echo "'-s' Argument must be a number" 
          OA_Usage
        fi
      ;;
    o)  if [ "$OPTARG" = "on" ] || [ "$OPTARG" = "off" ]; then
          if [ "$OPTARG" = "on" ]; then 
            opt_offline="on"
          else
            opt_offline="off"
          fi
        else
          echo ""
          echo "'-o' must be \"off\" or \"on\"" 
          OA_Usage
        fi
      ;;
    p)  OA_Getopt_Check "$options" "$OPTARG"
        opt_syslog_facility=$OPTARG
      ;;
    P)  if [ ! -e "$OPTARG" ]; then
          echo ""
          echo "The specified package file doesn't exist: \"${OPTARG}\""
          echo ""
          exit 1
        fi
        opt_packages=$OPTARG
      ;;
    q)  opt_quiet="n";;
    R)  opt_audit_remote="yes";;
    s)  OA_Getopt_Check "$options" "$OPTARG"
        opt_strcomputer=$OPTARG
      ;;
    S)  opt_safemode="yes";;
    t)  OA_Getopt_Check "$options" "$OPTARG"
        opt_uuid=$OPTARG
        case $OPTARG in
          uuid|mac)  opt_uuid=$OPTARG;;
          *)  echo ""; echo "UUID type needs to be mac or uuid."; OA_Usage;;
        esac
      ;;
    u)  OA_Getopt_Check "$options" "$OPTARG"
        opt_ssh_user=$OPTARG
      ;;
    U)  OA_Getopt_Check "$options" "$OPTARG"
        opt_web_url=$OPTARG
      ;;
    w)  if ! echo "$OPTARG" | grep -qE '^//.*\.vbs'; then 
          echo ""
          echo "UNC path needs to be in form //server/share/audit.vbs"
          echo ""
          OA_Usage
        fi
        # Format the UNC path so winexe understands it after it passes through bash
        opt_unc_path=$(echo "$OPTARG" | sed 's/^\/\//\\\\/g;s/\//\\\\/g')
        opt_type="yes"
      ;;
    y)  if [ ! -e "$OPTARG" ]; then
          echo ""
          echo "The LDAP password file doesn't exist: \"${OPTARG}\""
          echo ""
          exit 1
        fi
        opt_ad_pass="$OPTARG"
      ;;
    ?)  OA_Usage;;
  esac
done

###################################
#     Check Dependent Options     #
###################################

if [ -n "$opt_unc_path" -a -z "$opt_smb_credentials" ] | [ -n "$opt_smb_credentials" -a -z "$opt_unc_path" ]; then
  echo ""
  echo "Windows audits require the 'w' and 'A' options"
  OA_Usage
elif [ -n "$opt_audit_local" ]; then
  if [ -z "$opt_offline" ]; then
    echo ""
    echo "Local audits require the 'o' switch"
    OA_Usage
  elif [ -z "$opt_web_url" ] && [ "$opt_offline" = "on" ]; then
    echo ""
    echo "Local online audits require the 'U' option"
    OA_Usage
  fi
elif [ -n "$opt_audit_remote" ]; then
  if [ -z "$opt_strcomputer" ]; then
    echo ""
    echo "Remote audits require the 's' option"
    OA_Usage
  elif [ -z "$opt_type" ] && [ -z "$opt_web_url" ]; then 
    echo ""
    echo "Remote Linux audits require the 'U' option"
    OA_Usage
  fi
elif [ -n "$opt_audit_input" ]; then
  if [ -z "$opt_input_file" ] && [ -z "$opt_system_list" ]; then
    echo ""
    echo "Input file audits require the 'i' or 'C' option"
    OA_Usage
  elif [ -z "$opt_type" ] && [ -z "OPT_WEB_URL" ]; then
    echo ""
    echo "Linux input file audits require the 'U' option"
    OA_Usage
  fi 
elif [ -n "$opt_audit_domain" ]; then
  if [ -z "$opt_ldap_uri" ]; then
    echo ""
    echo "Missing the LDAP URI"
    echo "Domain audits require the 'H' option"
    OA_Usage
  elif [ -z "$opt_type" ] && [ -z "$opt_web_url" ]; then
    echo ""
    echo "Linux domain audits require the 'U' option"
    OA_Usage
  elif [ -z "$opt_ad_user" ] || [ -z "$opt_ad_pass" ]; then
    echo ""
    echo "Missing domain account or password file"
    echo "Domain audits require the 'y' and 'd' options"
    OA_Usage
  fi
fi

# Check for proper priveleges to run the script
if [[ $UID -ne 0 ]]; then
  if [ -z "$opt_root" ]; then
    echo ""
    echo "This script should normally be run with root priveleges (If auditing locally). See usage..."
    OA_Usage
  fi
fi

# Set the trap for cleanup
trap OA_Cleanup 0 1 2 3 6 15

###################################
#  Read in the Audit Config File  #
###################################

# Check for switches that override the audit.config first
if [ -n "$opt_audit_local" ]; then
  if [ "$opt_offline" = "on" ]; then
    strComputer="."
    online="yesxml"
    non_ie_page="$opt_web_url"
    verbose="${opt_verbose-"y"}"
    uuid_type="${opt_uuid-"uuid"}"
    ie_submit_verbose="y"
    software_audit="y"
  else
    strComputer="."
    online="n"
    verbose="${opt_verbose-"y"}"
    uuid_type="${opt_uuid-"uuid"}"
    software_audit="y"
  fi
elif [ -n "$opt_audit_remote" ]; then
  strComputer="$opt_strcomputer"
  input_file=""
  online="yesxml"
  non_ie_page="$opt_web_url"
  verbose="${opt_verbose-"y"}"
  uuid_type="${opt_uuid-"uuid"}"
  ie_submit_verbose="y"
  software_audit="y"
elif [ -n "$opt_audit_domain" ]; then
  audit_local_domain="y"
  local_domain="$opt_ldap_uri"
  strComputer=""
  input_file=""
  non_ie_page="$opt_web_url"
  verbose="${opt_verbose-"y"}"
  uuid_type="${opt_uuid-"uuid"}"
  number_of_audits="${opt_number_audits-"5"}"
  use_audit_log="${opt_log_config-"n"}"
  keep_audit_log="${opt_log_append-"n"}"
  ie_submit_verbose="y"
  software_audit="y"
elif [ -n "$opt_audit_input" ]; then
  strComputer=""
  input_file="${opt_input_file-"$opt_system_list"}"
  non_ie_page="$opt_web_url"
  verbose="${opt_verbose-"y"}"
  uuid_type="${opt_uuid-"uuid"}"
  number_of_audits="${opt_number_audits-"5"}"
  use_audit_log="${opt_log_config-"n"}"
  keep_audit_log="${opt_log_append-"n"}"
  ie_submit_verbose="y"
  software_audit="y"
else
  #  config_path: If the config parameter isn't used, it looks for the config in 
  #+ the working directory.
  config_path="${opt_config_path-"./audit.config"}"

  if [ -e "$config_path" ]; then
    # Format the config before looping through it
    config_formatted=$(sed "s/ //g;/^.*page=/s/audit_host+\"/\${audit_host}/g;/\(^'\|^$\|'.*$\|^#\)/d" "$config_path")

    #  Loop through the config pulling the variable names and values
    #+ using declare to set them on the fly to avoid using temp files
    for line in $config_formatted; do
      unset var_name var_value
      var_name=$(echo "$line" | awk -F= '{print $1}')
      var_value=$(echo "$line" | awk -F= '{print $2}' | sed 's/\(^"\|"$\)//g')
      echo "$line" | grep -q '^.*_page=\$' && var_value="${audit_host}${var_value/\$\{audit_host\}/}"
      declare $var_name=$var_value
    done

    # Check for script parameters to override ...
    input_file="${opt_input_file-"$input_file"}"
    strComputer="${opt_strcomputer-"$strComputer"}"
    local_domain="${opt_ldap_uri-"$local_domain"}"
    non_ie_page="${opt_web_url-"$non_ie_page"}"
    uuid_type="${opt_uuid-"$uuid_type"}"
    number_of_audits="${opt_number_audits-"$number_of_audits"}"
    verbose="${opt_verbose-"$verbose"}"
    use_audit_log="${opt_log_config-"$use_audit_log"}"
    keep_audit_log="${opt_log_append-"$keep_audit_log"}"
  else
    echo ""
    echo "$config_path not found. Using default settings. See the resulting text file when complete and submit manually."
    echo ""
    verbose="y"
    online="n"
    software_audit="y"
    strComputer="."
  fi
fi

###################################
#     Define Script Variables     #
###################################
#-Variables_Start-#

#  If you're not worried about attacks, you can just use the first one in
#+ the path. The "S" option controls this. 

if [ -z "$opt_safemode" ]; then
  oa_awk=$(which awk)
  oa_cat=$(which cat)
  oa_chage=$(which chage)
  oa_crontab=$(which crontab)
  oa_cut=$(which cut)
  oa_date=$(which date)
  oa_dmidecode=$(which dmidecode 2> /dev/null)
  oa_df=$(which df)
  oa_dpkg=$(which dpkg 2> /dev/null)
  oa_equery=$(which equery 2> /dev/null)
  oa_expr=$(which expr)
  oa_fdisk=$(which fdisk)
  oa_find=$(which find)
  oa_glxinfo=$(which glxinfo 2> /dev/null)
  oa_grep=$(which grep)
  oa_hal_find=$(which hal-find-by-property 2> /dev/null)
  oa_hal_get=$(which hal-get-property 2> /dev/null)
  oa_hal_cap=$(which hal-find-by-capability 2> /dev/null)
  oa_hal_list=$(which lshal 2> /dev/null)
  oa_hostname=$(which hostname)
  oa_hwinfo=$(which hwinfo 2> /dev/null)
  oa_ifconfig=$(which ifconfig)
  oa_ldapsearch=$(which ldapsearch 2> /dev/null)
  oa_logger=$(which logger)
  oa_lspci=$(which lspci 2> /dev/null)
  oa_lshw=$(which lshw 2> /dev/null)
  oa_lshal=$(which lshal 2> /dev/null)
  oa_lsusb=$(which lsusb 2> /dev/null)
  oa_opkg=$(which opkg 2> /dev/null)
  oa_pacman=$(which pacman 2> /dev/null)
  oa_pkg=$(which pkgtool 2> /dev/null)
  oa_rm=$(which rm)
  oa_route=$(which route 2> /dev/null)
  oa_rpm=$(which rpm 2> /dev/null)
  oa_scp=$(which scp 2> /dev/null)
  oa_sed=$(which sed)
  oa_sfdisk=$(which sfdisk 2> /dev/null)
  oa_sort=$(which sort)
  oa_ssh=$(which ssh 2> /dev/null)
  oa_stat=$(which stat)
  oa_tail=$(which tail)
  oa_tr=$(which tr)
  oa_udev_info=$(which udevinfo 2> /dev/null)
  oa_uname=$(which uname)
  oa_uniq=$(which uniq)
  oa_whereis=$(which whereis)
  oa_who=$(which who)
  oa_winexe=$(which winexe 2> /dev/null)
  oa_wget=$(which wget)
  oa_whoami=$(which whoami)
  oa_xdpyinfo=$(which xdpyinfo 2>/dev/null)
  oa_xrandr=$(which xrandr 2>/dev/null)
else
  oa_awk=/usr/bin/awk
  oa_cat=/bin/cat
  oa_chage=/usr/bin/chage
  oa_crontab=/usr/bin/crontab
  oa_cut=/usr/bin/cut
  oa_date=/bin/date
  oa_df=/bin/df
  oa_dmidecode=/usr/sbin/dmidecode
  oa_dpkg=/usr/bin/dpkg
  oa_equery=/usr/bin/equery
  oa_expr=/usr/bin/expr
  oa_find=/usr/bin/find
  oa_fdisk=/sbin/fdisk
  oa_glxinfo=/usr/bin/glxinfo
  oa_grep=/bin/grep
  oa_hal_find=/usr/bin/hal-find-by-property
  oa_hal_get=/usr/bin/hal-get-property
  oa_hal_cap=/usr/bin/hal-find-by-capability
  oa_hal_list=/usr/bin/lshal
  oa_hostname=/bin/hostname
  oa_ifconfig=/sbin/ifconfig
  oa_pkg=/var/log/packages
  oa_ldapsearch=/usr/bin/ldapsearch
  oa_logger=/usr/bin/logger
  oa_lshal=/usr/bin/lshal
  oa_lshw=/usr/bin/lshw
  oa_lspci=/usr/bin/lspci
  oa_lsusb=/usr/sbin/lsusb
  oa_opkg=/usr/bin/opkg
  oa_pacman=/usr/bin/pacman
  oa_pkg=/usr/bin/pkg
  oa_rm=/bin/rm
  oa_route=/sbin/route
  oa_rpm=/usr/bin/rpm
  oa_scp=/usr/bin/scp
  oa_sed=/bin/sed
  oa_sfdisk=/sbin/sfdisk
  oa_sort=/usr/bin/sort
  oa_ssh=/usr/bin/ssh
  oa_stat=/usr/bin/stat
  oa_tail=/usr/bin/tail
  oa_tr=/usr/bin/tr
  oa_udev_info=/usr/bin/udevinfo
  oa_uniq=/usr/bin/uniq
  oa_uname=/bin/uname
  oa_wget=/usr/bin/wget
  oa_whereis=/usr/bin/whereis
  oa_who=/usr/bin/who
  oa_whoami=/usr/bin/whoami
  oa_winexe=/usr/bin/winexe
  oa_xdpyinfo=/usr/bin/xdpyinfo
  oa_xrandr=/usr/bin/xrandr
fi

# Define variables to check on the system
oa_vars="awk dmidecode glxinfo grep hal-find-by-property hal-get-property hwinfo ldapsearch lshal lpstat lshw lspci lsusb scp sed ssh wget winexe xdpyinfo xrandr"

# Check if the given tool exists and mark it appropriately
for missing_command in $(echo "$oa_vars" | $oa_awk 'BEGIN{RS = ""; FS = "\n"}; {print $1}'); do
  if ! which $missing_command > /dev/null 2>&1; then
    case "$missing_command" in
      dmidecode)
        echo "dmidecode not found! Some information will be missing (such as RAM information)."
        oa_dmidecode_missing="yes"
        ;;
      hal-find-by-property|hal-get-by-property)
        echo "HAL component not found! A lot of information depends on HAL being available"
        oa_hal_missing="yes"
        ;;
      hwinfo)
        echo "hwinfo not found! Some information will be missing (such as Monitor information)."
        oa_hwinfo_missing="yes"
        ;;
      ldapsearch)
        # Only care if it's missing if a domain audit is specified.
        if [ "$audit_local_domain" = "y" -o "$audit_local_domain" = "Y" ] || [ -n "$opt_audit_domain" ]; then
	  if [ "$strComputer" = "" -a "$input_file" = "" ] || [ -n "$opt_audit_domain" ]; then
            echo "ldapsearch not found! ldapsearch needed (openldap/ldap-utils package) installed to do a domain audit."
	    exit 1
	  fi
        fi
	;;
      lshw)
        echo "lshw not found! Some information will be missing (such as detailed network adapter information)."
        oa_lshw_missing="yes"
        ;;
      lspci)
        echo "lspci not found! Some information will be missing (such as PCI device information)."
        oa_lspci_missing="yes"
        ;;
      ssh|scp)
        # Only care if it's missing if a remote linux audit is specified
        if [ -n "$input_file" -o -n "$strComputer" ] && [ -z "$opt_type" && "$strComputer" != "." ]; then
          echo "$missing_command not found! You need $missing_command installed to do a remote linux audit."
          exit 1
        elif [ "$audit_local_domain" = "y" -o "$audit_local_domain" = "Y" ] || [ -n "$opt_audit_domain" ]; then
	  if [ "$strComputer" = "" -a "$input_file" = "" ] || [ -n "$opt_audit_domain" ]; then
            if [ -z "$opt_type" ]; then
              echo "$missing_command not found! You need $missing_command installed to do a remote linux audit."
              exit 1
            fi
          fi
        fi
        ;;
      wget)
        echo "wget not found! Submitting audits will not work."
        oa_wget_missing="yes"
        ;;
      winexe)
        # Only care if it's missing if a Windows audit is specified.
        if [ -n "$opt_type" ]; then 
          echo "winexe not found! You need winexe installed to do a Windows audit."
          exit 1
        fi
	;;
      xrandr)
        echo "xrandr not found! Some information will be missing (Video Adapter information)."
        oa_xrandr_missing="yes"
        ;;
      awk|sed|grep)
        echo "Basic command line utility \"$missing_command\" is missing. Exiting the script."
	exit 1
	;;
    esac
  fi
done

# Check HAL and dmidecode version if the system has it...
if [ -z "$oa_hal_missing" ]; then
  # HAL commands may exist, but is it really running? lshal will fail if it isn't...
  if $oa_lshal -s > /dev/null 2>&1; then 
    hal_version="$($oa_hal_find --version 2> /dev/null | $oa_awk '{print $2}')"
  else
    echo "HAL doesn't appear to be running! A lot of information depends on HAL being available"
    oa_hal_missing="yes"
  fi 
fi

if [ -z "$oa_dmidecode_missing" ]; then
  dmidecode_version="$($oa_dmidecode --version /dev/null)"
fi

#-Variables_End-#
###################################
#      Remote Audits Section      #
###################################
#  This section checks the options from the audit.config and script
#+ parameters to decide what type of audit to do 
#  Adjust script_timeout for how long to wait before killing child
#+ processes (In minutes)
script_timeout=20

#  It's too messy to try to return a string from a child bash process
#+ so just define it here so it can be referred to for clean-up
# remote_script_name : The name of the script sent to the remote machine
# remote_script : Tmp location of the script before sending it to the machine
remote_script_name="audit_linux_ssh.$$"
remote_script="/tmp/${remote_script_name}"

if [ "$strComputer" != "." ] || [ "$input_file" != "" ]; then 
  if [ "$strComputer" != "." ]; then
    # An input file audit is specified if the below is met
    if [ "$input_file" != "" ]; then
      if [ -z "$opt_system_list" ] && [ ! -e "$input_file" ]; then
        OA_Audit_Log "" "log_start_failed" "input_file"
        OA_Trace "Input file \"${input_file}\" doesn't exist."
        exit 1
      fi
      # Remove trailing whitespace from the input file
      if [ -n "$opt_system_list" ]; then
        oa_input_list=$(echo "$opt_system_list" | $oa_awk 'BEGIN{RS = " "}; {print $1}' | $oa_sed '/^$/d');
        echo "$oa_input_list"
      else
        oa_input_list=$($oa_sed 's/[ \t]*$//g' "$input_file")
      fi
      # Execute SSH portion for input_file
      if [ -z "$opt_type" ]; then
        #  A default SSH user is needed since it's not required to specify
        #+ them in the input file. This way if some input entries have a 
        #+ ssh user listed, it will use that instead of the default. But
        #+ it can still fall back on the default if needed.
        if [ -z "$opt_ssh_user" ]; then
          echo "You need to specify a default SSH user when doing remote Linux audits"
          OA_Usage
        fi
        OA_Audit_Log "" "log_header"
        if [ -z "$opt_system_list" ]; then
          OA_Audit_Log "" "log_start_success" "input_file" "$(wc -l "$input_file" | $oa_cut -d" " -f1)"
          OA_Trace "-----------------------------------------------"
          OA_Trace "Processing input file: $input_file"
          OA_Trace "(Linux) Computers to audit: $(wc -l "$input_file" | $oa_cut -d" " -f1)"
          OA_Trace "-----------------------------------------------"
        fi
        OA_Process_Audits "$oa_input_list" "linux" "input_file"
      # Execute WINEXE portion for input_file
      else
        if [ -z "$opt_smb_credentials" ]; then
	  echo "You need to specify a samba credentials file for Windows audits"
          OA_Usage
        fi
        OA_Audit_Log "" "log_header"
        if [ -z "$opt_system_list" ]; then
          OA_Audit_Log "" "log_start_success" "input_file" "$(wc -l "$input_file" | $oa_cut -d" " -f1)"
          OA_Trace "-----------------------------------------------"
          OA_Trace "Processing input file: $input_file"
          OA_Trace "(Windows) Computers to audit: $(wc -l "$input_file" | $oa_cut -d" " -f1)"
          OA_Trace "-----------------------------------------------"
        fi
        OA_Process_Audits "$oa_input_list" "windows" "input_file"
      fi
    # Execute WINEXE portion for single remote audit
    elif [ "$strComputer" != "" ] && [ -n "$opt_type" ]; then
      if [ -z "$opt_smb_credentials" ]; then
        echo "You need to specify a samba credentials file for Windows audits"
        OA_Usage
      fi
      OA_Audit_Log "$strComputer" "log_header"
      OA_Remote_Win_Audit "$strComputer" &
      wait $!
    # Execute SSH portion for single remote audit
    elif [ "$strComputer" != "" ] && [ -z "$opt_type" ]; then
      OA_Audit_Log "$strComputer" "log_header"
      OA_Remote_Lin_Audit "$strComputer" "$opt_ssh_user"
    # A domain audit is specified if the below is met
    elif [ "$strComputer" = "" ] && [ "$input_file" = "" ]; then
      if [ "$audit_local_domain" = "y" ] || [ "$audit_local_domain" = "Y" ]; then
        if [ -z "$opt_ad_user" ] || [ -z "$opt_ad_pass" ]; then
          echo ""
          echo "Missing domain account or password file"
          echo "Domain audits require the 'a' and 'd' options"
          OA_Usage
        else
          if [ -z "$opt_smb_credentials" != "" ] && [ -n "$opt_type" ]; then
            echo ""
            echo "You need to specify a samba credentials file for Windows audits"
            OA_Usage
          fi
          OA_LDAP_Audit
        fi
      fi
    # Only this condition is left if all the above failed
    else
      OA_Trace "The strComputer variable is empty."
      exit 1
    fi
    OA_Audit_Log "" "log_end" "" "$SECONDS"
    #  Some background processes aren't always killed in the process audits function
    #+ so loop through jobs pid list on exit with kill 9.
    for i in $(jobs -p); do
      kill -9 $i > /dev/null 2>&1
    done
    exit 0
  fi
fi

###################################
#        Package Variables        #
###################################
#-SSH_AUDIT_SCRIPT-#

#  Make OA_PACKAGES blank if you want it to audit all packages.
if [ -z "$opt_packages" ]; then
# oa_packages=""
  oa_packages="apache apache2 apt azureus bash build-essential cdparanoia cdrdao cdrecord cpp cron \
cupsys cvs dbus dhcp3-client diff dpkg emacs epiphany-browser esound evolution firefox \
flashplugin-nonfree foomatic-db g++ gaim gcc gdm gedit gimp gnome-desktop gnucash gnumeric \
gtk+ httpd inkscape iptables k3b kdebase kdm koffice linux-image-386 metacity \
mozilla-browser mysql-admin mysql-query-browser mysql-server-4.1 nautilus openoffice.org \
openssh-client openssh-server pacman perl php4 php5 portage postfix postgresql python rdesktop \
rpm samba-common sendmail smbclient squid subversion sun-j2re1.5 swf-player synaptic thunderbird \
tsclient udev vim vnc-common webmin wine xfce4 xmms xserver-xorg"
else
  oa_packages="$($oa_cat "$opt_packages")"
fi

########################################
# Don't change the settings below here #
########################################

# Set report file name to match hostname.
hostname=$($oa_hostname)
# The location where the report file will be put if doing a remote audit
remote_report_loc="/tmp"

OA_Audit_Log "" "log_header"
OA_Audit_Log "$hostname" "audit_start"

if [ "$strComputer" = "." ]; then
  ReportFile=$hostname.txt
else
  ReportFile="$remote_report_loc/$hostname.txt"
fi

# If for some reason an old report file still exists, delete it.
if [ -e "$ReportFile" ]; then
  $oa_rm -f "$ReportFile"
fi

# Cleanup temp files created by the script
trap OA_Cleanup 0 1 2 3 6 15

###################################
#           LSHW Query            #
###################################

# Query the LSHW info all at once and dump it to a variable
if [ -z "$oa_lshw_missing" ]; then 
  OA_Trace "Querying LSHW..."
  lshw_query=$($oa_lshw -c net -c cpu -c tape 2> /dev/null)
  net_info_dump=$(echo "$lshw_query" | $oa_sed -n '/*-network/,/*-tape/p')
  cpu_info_dump=$(echo "$lshw_query" | $oa_sed -n '/*-cpu/,/*-network/p')
  tape_info_dump=$(echo "$lshw_query" | $oa_sed -n '/*-tape/,/$p/p')
fi

###################################
#          OS Information         #
###################################

OA_Trace "OS Information..."

# Operating System
name=$($oa_uname -s)
version=$($oa_uname -r)

#  If lsb_release is available, use that to get the OS info. Fallback on release files otherwise.  

if which lsb_release > /dev/null 2>&1; then
  lsb_release_present=1
  distribution="$(lsb_release -i | $oa_awk '{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')"
  os_release="$(lsb_release -d | $oa_awk '{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')"
  system_srvpack="$(lsb_release -c | $oa_awk '{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')"
fi

if [ "$name" = "Linux" ]; then
  if [ -e /etc/redhat-release ]; then
    if [ -z "$distribution" ]; then
      distribution="RedHat"
      os_release=$($oa_cat /etc/redhat-release)
    fi
    os_pck_mgr=$oa_rpm
  elif [ -e /etc/redhat-version ]; then
    if [ -z "$distribution" ]; then
      distribution="RedHat"
      os_release=$($oa_cat /etc/redhat-version)
    fi
    os_pck_mgr=$oa_rpm
  elif [ -e /etc/fedora-release ]; then
    if [ -z "$distribution" ]; then
      distribution="Fedora"
      os_release=$($oa_cat /etc/fedora-release)
    fi
    os_pck_mgr=$oa_rpm
  elif [ -e /etc/mandrake-release ]; then
    if [ -z "$distribution" ]; then
      distribution="Mandrake"
      os_release=$($oa_cat /etc/mandrake-release)
    fi
    os_pck_mgr=$oa_rpm
  elif [ -e /etc/SuSE-release ]; then
    if [ -z "$distribution" ]; then
      distribution="Novell SuSE"
      os_release=$($oa_awk 'BEGIN{IGNORECASE = "1"}; /suse/{print $0}' /etc/SuSE-release)
    fi
    os_pck_mgr=$oa_rpm
  elif [ -e /etc/arch-release ]; then
    if [ -z "$distribution" ]; then
      distribution="Arch"
      os_release=$($oa_cat /etc/issue)
    fi
    os_pck_mgr=$oa_pacman
  elif [ -e /etc/gentoo-release ]; then
    if [ -z "$distribution" ]; then
      distribution="Gentoo"
      os_release=$($oa_cat /etc/gentoo-release)
    fi
    os_pck_mgr=$oa_equery
  elif [ -e /etc/slackware-release ]; then
    if [ -z "$distribution" ]; then
      distribution="Slackware"
      os_release=$($oa_cat /etc/slackware-release)
    fi
    os_pck_mgr=$oa_pkg
  elif [ -e /etc/slackware-version ]; then
    if [ -z "$distribution" ]; then
      distribution="Slackware"
      os_release=$($oa_cat /etc/slackware-version)
    fi
    os_pck_mgr=$oa_pkg
  elif [ -e /etc/yellowdog-release ]; then
    if [ -z "$distribution" ]; then
      distribution="Yellow dog"
      os_release=$($oa_cat /etc/yellowdog-release)
    fi
    os_pck_mgr=$oa_rpm
  elif [ -e /etc/debian_version ] && [ "$($oa_grep 'Ubuntu' /etc/issue 2> /dev/null)" ]; then
    if [ -z "$distribution" ]; then
      distribution="Ubuntu"
      os_release=$($oa_cat /etc/issue)
    fi
    os_pck_mgr=$oa_dpkg
  elif [ -e /etc/debian_version ]; then
    if [ -z "$distribution" ]; then
      distribution="Debian"
      os_release=$($oa_cat /etc/issue)
     fi;
    os_pck_mgr=$oa_dpkg
  elif [ -e /etc/lfs-version ]; then
    if [ -z "$distribution" ]; then
      distribution="Linux from scratch"
      os_release=$($oa_cat /etc/lfs-version)
    fi
    os_pck_mgr=''
  elif [ -e /etc/issue ] && [ "$($oa_grep 'Openmoko' /etc/issue 2> /dev/null)" ]; then
    if [ -z "$distribution" ]; then
      distribution="Openmoko"
      os_release="Openmoko $($oa_cat /etc/version)"
    fi
    os_pck_mgr=$oa_opkg
  else
    distribution="unknown"
    os_release="unknown"
    os_pck_mgr=''
  fi
fi

if [ -z "$lsb_release_present" ]; then
  case $os_release in
    Ubuntu*5.10*) os_release="5.10 (Breezy Badger)";;
    Ubuntu*6.06*) os_release="6.06 (Dapper Drake)";;
    Ubuntu*6.10*) os_release="6.10 (Edgy Eft)";;
    Ubuntu*7.04*) os_release="7.04 (Fiesty Fawn)";;
    Ubuntu*7.10*) os_release="7.10 (Gutsy Gibbon)";;
    Ubuntu*8.04.1*) os_release="8.04.1 (Hardy Heron)";;
    Ubuntu*8.04*) os_release="8.04 (Hardy Heron)";;
    Ubuntu*8.10*) os_release="8.10 (Intrepid Ibex)";;
    Ubuntu*9.04*) os_release="9.04 (Jaunty Jackalope)";;
    Ubuntu*9.10*) os_release="9.10 (Karmic Koala)";;
    Debian*4.0*) os_release="Debian 4.0 (Etch)";;
    Debian*5.0*) os_release="Debian 5.0 (Lenny)";;
    *Arch*Core*Dump*) os_release="Arch Linux (Core Dump)";;
    *Arch*Linux*) os_release="Arch Linux";;
  esac
fi

###################################
#          Make the UUID          #
###################################

OA_Trace "Auditor..."

# Used for various HAL queries in different sections
if [ -z "$oa_hal_missing" ]; then
  # This seems to be the most portable way to get the root UDI for HAL
  pc=$($oa_lshal | $oa_awk -F\' '/^udi/{print $2; exit}');
fi

# Try to get domain info from likewise config, samba config, or kerberos config
if [ -e /etc/samba/lwiauthd.conf ]; then
  net_domain=$($oa_awk '/realm/{print $3}' /etc/samba/lwiauthd.conf)
elif $oa_grep -qE "^[^#][ \t]*default_realm" /etc/krb5.conf > /dev/null 2>&1; then
  net_domain=$($oa_awk '/default_realm/{print $3}' /etc/krb5.conf)
elif $oa_grep -qE "^[^#][ \t]*workgroup[ \t]*=" /etc/samba/smb.conf > /dev/null 2>&1; then
  net_domain=$($oa_awk '/^[^#][ \t]*workgroup[ \t]*=/{print $3}' /etc/samba/smb.conf)
fi

case $uuid_type in
  uuid)
    if [ -z "$oa_hal_missing" ] && ! echo "$hal_version" | $oa_grep -qE "0\.[0-5]\.([0-9]|10)\.[0-9]"; then
      uuid=$($oa_hal_get --udi $pc --key system.hardware.uuid)
    elif [ -z "$oa_hal_missing" ] && echo "$hal_version" | $oa_grep -qE "0\.[0-5]\.([0-9]|10)\.[0-9]"; then
      uuid=$($oa_hal_get --udi $pc --key smbios.system.uuid)
    elif [ -z "$oa_dmidecode_missing" ]; then
      uuid=$($oa_dmidecode --string system-uuid)
    fi;;
  mac)
    uuid=$($oa_ifconfig eth0 | $oa_awk '/HWaddr/{print $5}');;
  *)
    uuid="$hostname.$net_domain";;
esac

# If it fails to set the UUID set a failsafe one.
if [ -z "$uuid" ]; then
  uuid="$hostname.${net_domain-"unknown"}"
fi

audit_date="$($oa_date +%Y%m%d%H%M%S)"
date="$($oa_date +%d/%m/%Y%H:%M:%S)"
audit_user=$($oa_whoami)

echo "audit^^^$hostname^^^$audit_date^^^$uuid^^^$audit_user^^^$ie_submit_verbose^^^$software_audit^^^" >> $ReportFile

###################################
#       Network Information       #
###################################

OA_Trace "Network Interfaces..."

# Get main network interface info...

for i in $($oa_ifconfig -a | $oa_awk '/^[A-Za-z0-9]+/{print $1}' | $oa_sort); do
  # Unset some variables to avoid wrongly assigned values...
  unset net_hal_id net_parent net_device net_manufacturer net_service \
        net_dhcp_enabled net_dhcp_server net_speed net_connection_status \
        net_dhcp_lease_expires

  net_connection_id="$i"
  net_mac=$($oa_ifconfig "$i" | $oa_awk '/HWaddr/{print $5}')
  net_gateway=$($oa_route -n | $oa_awk '$1 ~ /0\.0\.0\.0/ {print $2}')
  net_type=$($oa_ifconfig "$i" | $oa_awk '/Link encap:/{split($0,a,":"); print a[2]}' | $oa_sed 's/HWaddr .*//')

  if [ -z "$oa_hal_missing" ] && $($oa_hal_find --key net.interface --string $i > /dev/null 2>&1); then 
    net_hal_id=$($oa_hal_find --key net.interface --string $i)
    net_parent=$($oa_hal_get --udi $net_hal_id --key info.parent)
    net_device=$($oa_hal_get --udi $net_parent --key info.product)
    net_manufacturer=$($oa_hal_get --udi $net_parent --key info.vendor 2> /dev/null)
  else
    net_device="unknown"
    net_manufacturer="unknown"
  fi

  if [ -z "$oa_lshw_missing" ] && $(echo "$net_info_dump" | $oa_grep -q 'logical name: '"$i"''); then
    net_info_config=$(echo "$net_info_dump" | $oa_awk 'BEGIN{RS = "\*"}; /'"$net_connection_id"'/{print $0}' \
      2> /dev/null | $oa_sed '/^$/d;/^-/d;s/^[ \t]*//g')
    net_driver_version=$(echo "$net_info_config" | $oa_awk 'BEGIN{RS = " "; FS = "="}; /driverversion/{print $2}') 
    net_driver_provider=$(echo "$net_info_config" | $oa_awk 'BEGIN{RS = " "; FS = "="}; /\<driver\>/{print $2}')
    net_speed=$(echo "$net_info_config" | $oa_awk 'BEGIN{RS = " "; FS = "="}; /speed/{print $2}' | $oa_sed 's/[^0-9]//g')
    net_description=$(echo "$net_info_config" | $oa_awk '/^product/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
  else
    net_description="unknown"
    net_driver_version="unknown"
    net_driver_provider="unknown"
  fi

  # Gather basic info from ifconfig output 
  if $oa_ifconfig "$net_connection_id" | $oa_grep -Eq 'inet add?r'; then
    net_ip=$($oa_ifconfig $net_connection_id | $oa_awk '/inet add?r:/{split($2,a,":"); print a[2]}')
    net_ipv6=$($oa_ifconfig $net_connection_id | $oa_awk '/inet6 add?r:/{print $3}')
    net_subnet=$($oa_ifconfig $net_connection_id | $oa_awk '/inet add?r:/{split($4,a,":"); print a[2]}')
    net_connection_status="Connected"
    net_ip_enabled="True"
  else
    # Interface is not online
    net_ip="--.--.--.--"
    net_ipv6=" "
    net_subnet="--.--.--.--"
    net_ip_enabled="Unknown"
  fi

  # Find information on DHCP leases, if the lease is active.
  if [ -e "$($oa_find /var/run -name "dhclient*${net_connection_id}.pid" -print0 -quit 2> /dev/null)" ]; then
    net_service="dhclient"
    # A lease seems to be active. Can we find the lease file?
    if [ -e "$($oa_find /var/lib -name "dhclient*${net_connection_id}.lease" -print0 -quit 2> /dev/null)" ]; then
      lease_file=$($oa_find /var/lib -name "dhclient*${net_connection_id}.lease" -print0 -quit 2> /dev/null)
      net_dhcp_server=$($oa_awk '/dhcp-server/{print $3; exit}' "$lease_file" | $oa_sed 's/\;//')
      #  The format for the date of the expiration uses one digit for the month
      #+ (1 for January instead of 01, etc) so it doesn't get formatted right. 
      #+ How to fix this using sed and regex of some sort?

      net_dhcp_lease_expires=$($oa_awk '/expire/{print $3 $4; exit}' "$lease_file" \
        | $oa_sed 's/\///g;s/\://g;s/\;//g')
      net_dhcp_enabled="True"
    else
      net_dhcp_enabled="False"
    fi
  elif [ -e "$(find /var/run -name "dhcpcd*${net_connection_id}.pid" -print0 -quit 2> /dev/null)" ]; then
    net_service="dhcpcd"
    net_dhcp_enabled="True"
  else
    net_service="none found"
    net_dhcp_enabled="False"
  fi 

  # Find dns servers from /etc/resolv.conf. Can only be three dns entries max in this file. 
  dns_count=0
  for k in $($oa_awk '/^name/{print $2}' /etc/resolv.conf); do
    dns_count=$($oa_expr $dns_count + 1)
    case $dns_count in 
      1) net_dns_server_1="$k";;
      2) net_dns_server_2="$k";;
      3) net_dns_server_3="$k";;
    esac	
  done

  echo "network^^^ $net_mac ^^^ $net_description ^^^ $net_dhcp_enabled ^^^ $net_dhcp_server ^^^ \
$hostname ^^^ $net_dns_server_1 ^^^ $net_dns_server_2 ^^^ $net_ip ^^^ $net_subnet ^^^ ^^^ ^^^ \
$net_type ^^^ $net_manufacturer ^^^ $net_gateway ^^^ $net_ip_enabled ^^^ $net_index ^^^ $net_service ^^^ \
$net_dhcp_lease_obtained ^^^ $net_dhcp_lease_expires ^^^ $net_dns_server_3 ^^^ $net_dns_domain ^^^ ^^^ ^^^ \
^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ ^^^ $net_connection_id ^^^ \
$net_connection_status ^^^ $net_speed ^^^ $net_driver_provider ^^^ $net_driver_version ^^^ ^^^" >> $ReportFile
done
 
#  This section needs to be here otherwise the timestamp/primary interface go missing.
echo "audit^^^$hostname^^^$audit_date^^^$uuid^^^$audit_user^^^$ie_submit_verbose^^^$software_audit^^^" >> $ReportFile

###################################
#         System 01 Info          #
###################################

# This shows who is logged in physically on Ubuntu and Suse. Other distros seem to default differently.
net_user_name=$($oa_who | $oa_awk '/(tty7|vc\/7|:0)/{print $1;exit}')
# Get the main IP based on the interface assigned to the first default gateway found
net_primary_ip=$($oa_ifconfig $($oa_route -n | $oa_awk '$4 ~ /UG/{print $8; exit}') | $oa_awk '/inet add?r:/{split($2,a,":"); print a[2]}')

echo "system01^^^ $net_primary_ip ^^^$net_domain^^^$net_user_name^^^ ^^^ ^^^ ^^^" >> $ReportFile
# Missing - AD Site
#         - Domain Controller Address
#         - Domain Controller Name

###################################
#   System/Timezone Information   #
###################################

OA_Trace "System Model..."

if [ -z "$oa_hal_missing" ] && ! echo "$hal_version" | $oa_grep -qE "0\.[0-5]\.([0-9]|10)\.[0-9]"; then
  pc_manufacturer=$($oa_hal_get --udi $pc --key system.hardware.vendor)
  pc_model=$($oa_hal_get --udi $pc --key system.hardware.product)
  pc_type=$($oa_hal_get --udi $pc --key system.formfactor)
  pc_serial=$($oa_hal_get --udi $pc --key system.hardware.serial)
elif [ -z "$oa_hal_missing" ] && echo "$hal_version" | $oa_grep -qE "0\.[0-5]\.([0-9]|10)\.[0-9]"; then
  pc_manufacturer=$($oa_hal_get --udi $pc --key smbios.system.manufacturer)
  pc_model=$($oa_hal_get --udi $pc --key smbios.system.product)
  pc_type=$($oa_hal_get --udi $pc --key system.formfactor)
  pc_serial=$($oa_hal_get --udi $pc --key smbios.system.serial)
elif [ -z "$oa_dmidecode_missing" ]; then
  echo "In Third IF"
  pc_type=$($oa_dmidecode --string chassis-type)
  pc_manufacturer=$($oa_dmidecode --string chassis-manufacturer)
  pc_model=$($oa_dmidecode --string system-product-name)
  pc_serial=$($oa_dmidecode --string chassis-serial-number)
fi

num_cpu=$($oa_grep -c '^processor' /proc/cpuinfo)

# Total system RAM
ram_sizekb=$($oa_awk '/MemTotal/{print $2}' /proc/meminfo)
ram_size=$($oa_expr $ram_sizekb / 1024)

if [ -f /etc/timezone ]; then
  pc_country=$($oa_cat /etc/timezone)
elif [ -e /etc/rc.conf ]; then
  pc_country=$($oa_awk -F"\"" '/^TIMEZONE/{print $2}' /etc/rc.conf)
else
  pc_country="Unknown"
fi

pc_timezone=$($oa_date +%:z)

echo "system02^^^$pc_model^^^$hostname^^^$num_cpu^^^ ^^^ ^^^$pc_type^^^$ram_size^^^$pc_serial^^^\
$pc_manufacturer^^^ ^^^$pc_country^^^$pc_timezone^^^^^^" >> $ReportFile
# Missing - Registered Owner
#         - Domain Role

###################################
#  BIOS/Install/Boot Information  #
###################################

OA_Trace "BIOS..."

if [ -z "$oa_hal_missing" ] && ! echo "$hal_version" | $oa_grep -qE "0\.[0-5]\.([0-9]|10)\.[0-9]"; then
  pc_uuid=$($oa_hal_get --udi $pc --key system.hardware.uuid)
  pc_serial=$($oa_hal_get --udi $pc --key system.hardware.serial)
  pc_bios_date=$($oa_hal_get --udi $pc --key system.firmware.release_date)
  pc_bios_version=$($oa_hal_get --udi $pc --key system.firmware.version)
  pc_bios_description=$($oa_hal_get --udi $pc --key system.hardware.product)
  pc_bios_manufacturer=$($oa_hal_get --udi $pc --key system.chassis.manufacturer)
  system_serial=$($oa_hal_get --udi $pc --key system.hardware.serial 2>/dev/null)
elif [ -z "$oa_hal_missing" ] &&  echo "$hal_version" | $oa_grep -qE "0\.[0-5]\.([0-9]|10)\.[0-9]"; then
  pc_uuid=$($oa_hal_get --udi $pc --key smbios.system.uuid)
  pc_serial=$($oa_hal_get --udi $pc --key smbios.system.serial)
  pc_bios_date=$($oa_hal_get --udi $pc --key smbios.bios.release_date)
  pc_bios_version=$($oa_hal_get --udi $pc --key smbios.bios.version)
  pc_bios_description=$($oa_hal_get --udi $pc --key smbios.system.product)
  pc_bios_manufacturer=$($oa_hal_get --udi $pc --key smbios.chassis.manufacturer 2> /dev/null || \
                         $oa_hal_get --udi $pc --key system.formfactor)
elif [ -z "$oa_dmidecode_missing" ]; then 
  pc_uuid=$($oa_dmidecode --string system-uuid)
  pc_serial=$($oa_dmidecode --string chassis-serial-number)
  pc_bios_date=$($oa_dmidecode --string bios-release-date)
  pc_bios_version=$($oa_dmidecode --string bios-version)
  pc_bios_manufacturer=$($oa_dmidecode --string bios-vendor)
  system_serial=$($oa_dmidecode --string baseboard-serial-number)
fi

# Seems to only be available in dmidecode info
if [ -z "$oa_dmidecode_missing" ]; then
  pc_bios_asset=$($oa_dmidecode --string chassis-asset-tag)
fi
  
if [ ! -n "$system_serial" ]; then
  system_serial="???"
fi

#  The install date can be found by stat'ing something that shouldn't change, the below seems 
#+ like a good candidate...
if [ -e /lost+found ]; then
  os_install=$($oa_stat /lost+found | $oa_awk '/Change/{print $2}')
else
  os_install=$($oa_stat /etc/*release 2> /dev/null | $oa_awk '/Change/{print $2}')
fi

os_lastboot=$($oa_date -d date -d @$($oa_awk '/^btime/{print $2}' /proc/stat) +%Y%m%d%I%M)

#  The language is actually determined in the admin_pc_add_2.php page and is specific to the way 
#+ that Windows identifies the language. So return a number that page understands via a case.

case $(echo "$LANG" | $oa_cut -d"." -f"1") in
  "en_US") os_lang=1033;;
  "en_GB") os_lang=2057;;
  "fr") os_lang=1036;;
  "ja") os_lang=1041;;
  "zh") os_lang=4;;
  "de") os_lang=1031;;
  "es") os_lang=2058;;
  "ru") os_lang=1049;;
esac

mount_point=$($oa_awk '/ \/ /{print $1}' /etc/mtab)

echo "system03^^^$mount_point^^^$version^^^Linux^^^$distribution^^^$country^^^$os_release^^^\
$os_install^^^ ^^^ $os_lang ^^^ ^^^$system_serial^^^$system_srvpack^^^$version^^^^^^$os_lastboot^^^" >> $ReportFile
# Missing - Description
#         - Organisation
#         - Registered User

echo "bios^^^$pc_bios_description^^^$pc_bios_manufacturer^^^$pc_serial^^^$pc_bios_smversion^^^\
$pc_bios_version^^^$pc_bios_asset" >> $ReportFile

###################################
#         CPU Information         #
###################################

OA_Trace "Processor..."

for i in $($oa_awk '/^processor/{print $3}' /proc/cpuinfo); do
  cpu_proc_info=$($oa_awk 'BEGIN{ RS=""; FS="\n" }; /processor[ \t]*: '"$i"'/{print $0}' /proc/cpuinfo)
  next_cpu=$($oa_expr $i + 1)

  oa_cpu_name=$(echo "$cpu_proc_info" | $oa_awk '/^model name/{for (u=4; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
  oa_cpu_freq=$(echo "$cpu_proc_info" | $oa_awk '/^cpu MHz/{split($4,a,"."); print a[1]}')
  oa_cpu_manufacturer=$(echo "$cpu_proc_info" | $oa_awk '/^vendor_id/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')

  if [ -z "$oa_lshw_missing" ]; then
    oa_cpu_info=$(echo "$cpu_info_dump" | $oa_sed -n "/cpu:$i/,/cpu:$next_cpu/p")
    oa_cpu_clock=$(echo "$oa_cpu_info" | $oa_sed -n '/clock/s/[^0-9]//gp')
    oa_cpu_socket=$(echo "$oa_cpu_info" | $oa_awk '/[ \t]*slot:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
  fi

  if [ "$oa_cpu_socket" = "None" ] || [ -n "$oa_cpu_socket" -o -z "$oa_cpu_socket" ]; then
    oa_cpu_socket="Unknown"
  fi

  if [ -z "$oa_hal_missing" ]; then 
    if $oa_hal_find --key power_management.type --string acpi > /dev/null 2>&1; then
      oa_cpu_udi=$($oa_hal_cap --capability processor 2> /dev/null | $oa_grep 'CPU'"$i"'$')
      oa_cpu_power=$($oa_hal_get --udi $oa_cpu_udi --key processor.can_throttle 2> /dev/null)
    else
      # If ACPI isn't enabled, the above won't be available.
      oa_cpu_power='???'
    fi
  fi

  if [ -z "$oa_dmidecode_missing" ]; then
    oa_cpu_voltage=$($oa_dmidecode -t processor | $oa_awk '/[ \t]*Voltage:/{print $2}')
  fi

  echo "processor^^^$oa_cpu_name^^^$oa_cpu_freq^^^$oa_cpu_voltage^^^$i^^^$oa_cpu_clock^^^\
$oa_cpu_manufacturer^^^$oa_cpu_freq^^^$oa_cpu_name^^^$oa_cpu_power^^^$oa_cpu_socket^^^" >> $ReportFile
done

###################################
#       Memory Information        #
###################################

OA_Trace "Memory..."

if [ -z "$oa_dmidecode_missing" ]; then
  for i in $($oa_dmidecode -t 17 | $oa_awk '/DMI type 17/{print $2}'); do
    bank_info=$($oa_dmidecode -t 17 | $oa_sed -n '/^Handle '"$i"'/,/^$/p')
    mem_bank=$(echo "$bank_info" | $oa_awk '/^[^B]+Locator:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    mem_formfactor=$(echo "$bank_info" | $oa_awk '/Form Factor/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    mem_detail_type=$(echo "$bank_info" | $oa_awk '/Type Detail:/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    mem_size=$(echo "$bank_info" | $oa_awk '/Size:/{print $2}')
    mem_speed=$(echo "$bank_info" | $oa_awk '/Speed:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    mem_detail=$(echo "$bank_info" | $oa_awk '/Type:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    mem_tag=$(echo "$bank_info" | $oa_awk '/Bank L.*:/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    # Ignore empty banks
    if [ "$mem_size" != "No" ]; then
      echo "memory^^^$mem_bank^^^$mem_formfactor^^^$mem_detail^^^$mem_detail_type^^^\
$mem_size^^^$mem_speed^^^$mem_tag^^^" >> $ReportFile
    fi
  done
fi

###################################
#         Onboard Devices         #
###################################

OA_Trace "Onboard Devices..."

if [ -z "$oa_dmidecode_missing" ]; then
  for i in $($oa_dmidecode -t baseboard | $oa_awk 'BEGIN{RS = ""; FS = "\n"}; /On Board/{split($1,a," "); print a[2]}'); do
    onboard_info=$($oa_dmidecode -t baseboard | $oa_awk 'BEGIN{RS=""; FS="\n"}/Handle '"$i"'/{print $0}')
    onboard_type=$(echo "$onboard_info" | $oa_awk '/[ \t]*Type:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    onboard_description=$(echo "$onboard_info" | $oa_awk '/[ \t]*Description:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    echo "onboard^^^$onboard_description^^^$onboard_type^^^" >> $ReportFile
  done
fi

###################################
#     PCI Device Information      #
###################################

OA_Trace "PCI Devices..."

if [ -z "$oa_lspci_missing" ]; then
  oa_pci_list=$($oa_lspci -vm)
  for i in $($oa_lspci -vm | $oa_awk '/^Device:[ \t]*[0-9]+:[0-9]+/{print $2}'); do
    oa_pci_info=$(echo "$oa_pci_list" | $oa_sed -n '/Device:[ \t]*'"$i"'/,/^$/p' \
                | $oa_sed '/Device:[ \t]*'"$i"'/d')
    oa_pci_type=$(echo "$oa_pci_info" | $oa_awk '/^Class:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    oa_pci_name=$(echo "$oa_pci_info" | $oa_awk '/^Device:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    oa_pci_manufacturer=$(echo "$oa_pci_info" | $oa_awk '/^Vendor:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    oa_pci_dev_id="$i"

    case $oa_pci_type in
      VGA*compatible*controller*)
        OA_Trace "Video Card..."
        # How to handle multiple screens/cards?
        video_ram=$($oa_lspci -vs $i | $oa_awk -F"[" '/, prefetchable/{print $2}' | $oa_sed 's/[^0-9]//g')
        # How to format the below from bits to decimal format?
        video_color_depth=$($oa_xdpyinfo 2> /dev/null | $oa_awk '/depth of root window/{print $5}')
        video_horizontal_resolution=$($oa_xdpyinfo 2> /dev/null | $oa_awk '/dimensions/{split($2,a,"x");print a[1]}') 
        video_vertical_resolution=$($oa_xdpyinfo 2> /dev/null | $oa_awk '/dimensions/{split($2,a,"x");print a[2]}')
        #  Some versions of xrandr display info quite differently, but this
        #+ is the only command I could find to get the refresh rate.
        video_current_refresh=$($oa_xrandr --prop 2> /dev/null | $oa_awk '/\*/{print $2}' 2> /dev/null \
                                | $oa_tr "*" " ")
        video_driver_version=$($oa_glxinfo 2> /dev/null | $oa_awk '/OpenGL ver/{for (u=4; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
        video_driver_name=$($oa_lspci -vs $i | $oa_awk -F":" '/Kernel driver/{print $2}')
        video_driver="$video_driver_name $video_driver_version"

        if [ "$video_horizontal_resolution" = "" ]; then
          video_horizontal_resolution="Unknown"
          video_vertical_resolution="Unknown"
        fi

        echo "video^^^$video_ram^^^$oa_pci_manufacturer - $oa_pci_name^^^$video_horizontal_resolution^^^ ^^^\
$video_current_refresh^^^$video_vertical_resolution^^^$oa_pci_manufacturer - $oa_pci_name^^^0000-00-00^^^\
$video_driver^^^ ^^^ ^^^$oa_pci_dev_id^^^" >> $ReportFile
        # Missing - Num colours
        #         - Driver Date
        #         - Max Refresh Rate
        #         - Min Refresh Rate
        ;;
      Audio*device*|Multimedia*controller*)
        OA_Trace "Sound Card..."
        echo "sound^^^$oa_pci_manufacturer^^^$oa_pci_name^^^$oa_pci_dev_id^^^" >> $ReportFile
        ;;
      RAID*controller*|SCSI*controller*|SATA*controller*)
        OA_Trace "SCSI/SATA Controllers..."
	echo "scsi_controller^^^$oa_pci_name^^^$oa_pci_dev_id^^^$oa_pci_manufacturer^^^" >> $ReportFile
        ;;
      Modem*|Communication*controller*)
        OA_Trace "Modem..."
	echo "modem^^^ ^^^ ^^^$oa_pci_name^^^$oa_manufacturer^^^$oa_pci_dev_id^^^" >> $ReportFile
        # Missing - Attached To
        #         - Country Selected
        ;;
      System*peripheral*)
        OA_Trace "Onboard Device..."
        echo "onboard^^^$oa_pci_manufacturer^^^$oa_pci_name^^^" >> $ReportFile
        ;;
    esac
  done
fi

###################################
#         Tape Information        #
###################################

OA_Trace "Tape Device..."

if [ -z "$oa_lshw_missing" ]; then
  if [ -n "$tape_info_dump" ]; then
    tape_caption=$(echo "$tape_info_dump" | $oa_awk '/product:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    tape_description=$(echo "$tape_info_dump" | $oa_awk '/description:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    tape_manufacturer=$(echo "$tape_info_dump" | $oa_awk '/vendor:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    tape_name=$(echo "$tape_info_dump" | $oa_awk '/logical name:/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    tape_dev_id=$(echo "$tape_info_dump" | $oa_awk '/bus info:/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    echo "tape^^^$tape_caption^^^$tape_description^^^$tape_manufacturer^^^$tape_name^^^$tape_dev_id^^^" >> $ReportFile
  fi
fi

###################################
#       Monitor Information       #
###################################

OA_Trace "Monitor..."

if [ -z "$oa_hwinfo_missing" ]; then
  oa_monitor_dump="$oa_hwinfo --monitor"
  for i in $(echo "$oa_monitor_dump" | $oa_awk '/Unique ID:/{print $3}'); do
    oa_monitor_info=$(echo "$oa_monitor_dump" | $oa_awk 'BEGIN{ RS = "" } /'"$i"'/{print $0}' )
    monitor_manfucaturer=$(echo "$oa_monitor_info" | $oa_awk '/Vendor/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    monitor_deviceid=$(echo "$oa_monitor_info" | $oa_awk '/Device:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    monitor_model=$(echo "$oa_monitor_info" | $oa_awk '/Model:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
  
    echo "monitor_sys^^^$monitor_manufacturer^^^$monitor_deviceid^^^ ^^^$monitor_model^^^ ^^^ ^^^" >> $ReportFile
  done
fi

###################################
#     USB Device Information      #
###################################

OA_Trace "USB Devices..."

for i in $($oa_lsusb 2> /dev/null | $oa_awk '{print $2":"$4}' | $oa_sed 's/.$//'); do
  usb_vendor_check=$($oa_lsusb -s $i 2> /dev/null | $oa_awk '{for (u=7; u<=8; u++){printf("%s ", $u)}printf("\n")}')
  if [ "$usb_vendor_check" != "" ] && ! echo "$usb_vendor_check" | $oa_grep -iq 'Linux Foundation'; then
    unset usb_caption
    lsusb_info=$($oa_lsusb -s $i -v 2> /dev/null)
    usb_vendor=$(echo "$lsusb_info" | $oa_awk '/idVendor/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    usb_product=$(echo "$lsusb_info" | $oa_awk '/idProduct/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    usb_caption=$(echo "$lsusb_info" | $oa_awk '/bInterfaceClass/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n");exit}')
    usb_device_id=$($oa_lsusb -s $i | $oa_awk '{print $1"-"$2","$3"-"$4}' | $oa_sed 's/.$//')
    if [ -n "$usb_product" ] && ! echo "$usb_caption" | $oa_grep -qE '^Hub[ \t]*$'; then
      echo "usb^^^$usb_product^^^$usb_caption^^^$usb_vendor^^^$usb_device_id^^^" >> $ReportFile
    fi
  fi
done

###################################
#     Motherboard Information     #
###################################

OA_Trace "Motherboard..."

mobo_manufacturer=$($oa_dmidecode --string baseboard-manufacturer 2> /dev/null)
mobo_product=$($oa_dmidecode --string baseboard-product-name 2> /dev/null)
mobo_memoryslots=$($oa_dmidecode -t 16 2> /dev/null | 
                   $oa_awk '/Number Of Devices/{print $4}' 2> /dev/null)

# Fall back to HAL if dmidecode fails
if [ "$mobo_manufacturer" == "" ]; then
  mobo_manufacturer=$($oa_hal_get --udi $pc --key system.board.vendor 2> /dev/null || \
                       $oa_hal_get --udi $pc --key system.vendor 2> /dev/null)
fi

if [ "$mobo_product" == "" ]; then
  mobo_product=$($oa_hal_get --udi $pc --key system.board.product 2> /dev/null || \
                 $oa_hal_get --udi $pc --key system.product 2> /dev/null)
fi

# num_cpu is pulled from the system02 section.

echo "motherboard^^^$mobo_manufacturer^^^$mobo_product^^^$num_cpu^^^$mobo_memoryslots^^^" >> $ReportFile

###################################
#        Software Packages        #
###################################
if [ "$software_audit" = "y" -o "$software_audit" = "Y" ]; then
  OA_Trace "Packages..."

  # Determine whether to query all packages or just a list of packages.
  if [ ! -n "$oa_packages" ]; then
    SoftwareReport="${ReportFile}.software"
    case $os_pck_mgr in
        "$oa_dpkg") oa_package_track=$(env COLUMNS=200 $oa_dpkg -l | $oa_awk '{print $2}' | $oa_sort);;
         "$oa_rpm") oa_package_track=$($oa_rpm -qa | $oa_sort);;
      "$oa_pacman") oa_package_track=$($oa_pacman -Qe | $oa_sort);;
      "$oa_equery") oa_package_track=$($oa_equery list | $oa_awk -F"/" '{match($2,/[-0-9.]*[0-9.r]*$/); print substr($2,0,RSTART-1)}' | $oa_sort);;
         "$oa_pkg") oa_package_track=$oa_packages;;
        "$oa_opkg") oa_package_track=$($oa_opkg list_installed | $oa_awk -F" - " '{print $1}' | $oa_sort)
    esac
  else
    oa_package_track=$oa_packages
  fi

  case $os_pck_mgr in
    "$oa_dpkg")
      for name in $oa_package_track; do
        package_info=$(dpkg -s $name 2> /dev/null)
        oa_package_version=$(echo "$package_info" | $oa_awk '/^[ \t]*Version:/{print $2}')
        oa_package_name=$(echo "$package_info" | $oa_awk '/^[ \t]*Package:/{print $2}')
        oa_package_url=$(echo "$package_info" | $oa_awk '/^[ \t]*Homepage:/{print $2}')
        if [ "$oa_package_version" ] ; then
          echo "software^^^$oa_package_name^^^$oa_package_version^^^ ^^^ ^^^ ^^^$oa_package_url^^^ ^^^ ^^^ $oa_package_url ^^^ ^^^" >> $ReportFile
        fi
      done
      ;;
    "$oa_rpm")
      for name in $oa_package_track; do
        package_info=$($oa_rpm -qi $name 2> /dev/null)
        oa_package_version=$(echo "$package_info" | $oa_awk '/Version +:/{print $3}')
        oa_package_name=$(echo "$package_info" | $oa_awk '/Name +:/{print $3}')
        oa_package_url=$(echo "$package_info" | $oa_awk '/URL +:/{print $3}')
        if [ "$oa_package_version" ] ; then
          echo "software^^^$oa_package_name^^^$oa_package_version^^^ ^^^ ^^^ ^^^$oa_package_url^^^ ^^^  ^^^ $oa_package_url ^^^ ^^^" >> $ReportFile
        fi
      done
      ;;
    "$oa_pacman")
      for name in $oa_package_track; do
        package_info=$($oa_pacman -Qi $name 2> /dev/null)
        oa_package_version=$(echo "$package_info" | $oa_awk '/^Version/{print $3}')
        oa_package_name=$(echo "$package_info" | $oa_awk '/^Name/{print $3}')
        oa_package_url=$(echo "$package_info" | $oa_awk '/^URL/{print $3}')
        if [ "$oa_package_version" ] ; then
          echo "software^^^$oa_package_name^^^$oa_package_version^^^ ^^^ ^^^ ^^^$oa_package_url^^^ ^^^  ^^^ $oa_package_url ^^^ ^^^" >> $ReportFile
        fi
      done
      ;;
    "$oa_equery")
      for name in $oa_package_track; do
        package_info=$($oa_equery list -e $name)
        oa_package_version=$(echo "$package_info" | $oa_awk -F"/" '{match($2,/([-0-9.]*[-0-9.rp_]*)$/,a); print a[1]}' | $oa_sed 's/^-//;/^$/d')
        oa_package_name=$name
        if [ "$oa_package_version" ] ; then
          echo "software^^^$oa_package_name^^^$oa_package_version^^^ ^^^ ^^^ ^^^ ^^^ ^^^  ^^^ ^^^ ^^^" >> $ReportFile
        fi
      done
      ;;
    "$oa_pkg")
      oa_all_packages=$(ls /var/log/packages)
        if [ "$oa_package_track" = "" ]; then
        for oa_package_line in $oa_all_packages; do
          oa_package_name=$(echo $oa_package_line | $oa_awk '{ match($0, /^([a-zA-Z\-]*)\-([0-9].*)$/, a); print a[1] }' 2> /dev/null)
          oa_package_version=$(echo $oa_package_line | $oa_awk '{ match($0, /^([a-zA-Z\-]*)\-([0-9].*)$/, a); print a[2] }' 2> /dev/null)
          if [ "$oa_package_name" ] && [ "$oa_package_version" ]; then
            echo "software^^^$oa_package_name^^^$oa_package_version^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> $ReportFile
          fi
        done
      else
        for oa_package_name in $oa_package_track; do
          oa_package_version=$(ls /var/log/packages | $oa_grep "$oa_package_name" | $oa_tail -n1 | $oa_awk '{ match($0, /^([a-zA-Z\-]*)\-([0-9].*)$/, a); print a[2] }' 2> /dev/null)
          if [ "$oa_package_version" ]; then
            echo "software^^^$oa_package_name^^^$oa_package_version^^^^^^^^^^^^^^^^^^^^^^^^^^^" >> $ReportFile
          fi
        done
      fi
      ;; 
    "$oa_opkg")
      package_info=$($oa_opkg list_installed)
      for name in $oa_package_track; do
        oa_package_version=$(echo "$package_info" | $oa_awk -F" - " '/^'"$name"' /{print $2}')
        oa_package_name=$name
        if [ "$oa_package_version" ] ; then
          echo "software^^^$oa_package_name^^^$oa_package_version^^^ ^^^ ^^^ ^^^ ^^^ ^^^  ^^^ ^^^ ^^^" >> $ReportFile
        fi
      done
      ;;
  esac
fi

###################################
#       Printer Information       #
###################################

OA_Trace "Printers..."

#  The printer information currently doesn't seem to get added even though
#+ it seems to get pulled fine.

if [ -e /etc/cups/printers.conf ]; then
  for i in $($oa_awk '/<Printer /{gsub(/\>/,"",$2); print $2}' /etc/cups/printers.conf 2> /dev/null); do
    printer_options=$($oa_awk 'BEGIN{ RS = "\<\/Printer\>" } /'"$i"'/{print $0}' /etc/cups/printers.conf 2> /dev/null)
    printer_caption=$(echo "$printer_options" | $oa_awk '/^\<State\>/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    printer_location=$(echo "$printer_options" | $oa_awk '/^Location/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    printer_shared=$(echo "$printer_options" | $oa_awk '/^Shared/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    printer_port_name=$(echo "$printer_options" | $oa_awk '/^DeviceURI/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    printer_system_name=$(echo "$printer_options" | $oa_awk '/^Info/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
  
    echo "printer^^^$printer_caption^^^$printer_local^^^$printer_port_name^^^$printer_shared^^^ ^^^$printer_system_name^^^$printer_location^^^" >> $ReportFile
  done
fi

#  This section needs to be here otherwise the timestamp/primary interface go missing.
echo "audit^^^$hostname^^^$audit_date^^^$uuid^^^$audit_user^^^$ie_submit_verbose^^^$software_audit^^^" >> $ReportFile

###################################
#      Storage Information        #
###################################

OA_Trace "Storage..."

# Hard Disks
if [ -z "$oa_hal_missing" ]; then
  for i in $($oa_hal_find --key storage.drive_type --string disk); do
    disk_vendor=$($oa_hal_get --udi $i --key storage.vendor)
    disk_path=$($oa_hal_get --udi $i --key block.device)
    disk_model=$($oa_hal_get --udi $i --key storage.model)
    disk_size=$($oa_hal_get --udi $i --key storage.size 2> /dev/null)
    disk_serial=$($oa_hal_get --udi $i --key storage.serial 2> /dev/null)
    disk_bus=$($oa_hal_get --udi $i --key storage.bus)
    disk_parent_udi=$($oa_hal_get --udi $i --key info.parent)
    disk_scsi_bus=$($oa_hal_get --udi $disk_parent_udi --key scsi.bus 2> /dev/null)
    disk_scsi_lun=$($oa_hal_get --udi $disk_parent_udi --key scsi.lun 2> /dev/null)
    disk_partitions=$($oa_sfdisk -l $disk_path 2> /dev/null \
                      | $oa_grep -Evc "$disk_path:|Units =|Device Boot|Empty|Extended|^$")
    # The size value varies too much between bus types in HAL, so use fdisk
    disk_size=$($oa_fdisk -s $disk_path 2> /dev/null)
    disk_size=$($oa_expr $disk_size / 1024)

    echo "harddrive^^^$disk_path^^^$disk_path^^^$disk_bus^^^$disk_vendor^^^$disk_model^^^$disk_partitions^^^$disk_scsi_bus^^^$disk_scsi_lun^^^^^^$disk_size^^^$disk_path^^^" >> $ReportFile
    # Missing
    #         - scsi port
  done
else
  for i in $($oa_fdisk -l | $oa_awk '$1 ~ /^\//{ match($1,/(\/dev\/[a-z][a-z][a-z])/); print substr($1,RSTART,RLENGTH) }' | $oa_sort | uniq); do
    disk_path="$i"
    disk_vendor=$($oa_udev_info -q env -n $disk_path | $oa_awk '$1 ~ /ID_VENDOR=/{split($1,a,"="); print a[2]}')
    disk_model=$($oa_udev_info -q env -n $disk_path | $oa_awk '$1 ~ /ID_MODEL=/{split($1,a,"="); print a[2]}')
    disk_serial=$($oa_udev_info -q env -n $disk_path | $oa_awk '$1 ~ /ID_SERIAL=/{split($1,a,"="); print a[2]}')
    disk_bus=$($oa_udev_info -q env -n $disk_path | $oa_awk '$1 ~ /ID_BUS=/{split($1,a,"="); print a[2]}')
    disk_parent_udi=""
    disk_scsi_bus=""
    disk_scsi_lun=""
    disk_partitions=$($oa_sfdisk -l $disk_path 2> /dev/null | $oa_grep -Evc "$disk_path:|Units =|Device Boot|Empty|Extended|^$")
    disk_size=$($oa_fdisk -s $disk_path 2> /dev/null)
    disk_size=$($oa_expr $disk_size / 1024)

    echo "harddrive^^^$disk_path^^^$disk_path^^^$disk_bus^^^$disk_vendor^^^$disk_model^^^$disk_partitions^^^$disk_scsi_bus^^^$disk_scsi_lun^^^^^^$disk_size^^^$disk_path^^^" >> $ReportFile
    # Missing
    #         - scsi port
  done
fi

###################################
#         Optical Drives          #
###################################

if [ -z "$oa_hal_missing" ]; then
  for i in $($oa_hal_find --key storage.drive_type --string cdrom); do
    cd_vendor=$($oa_hal_get --udi $i --key storage.vendor)
    cd_path=$($oa_hal_get --udi $i --key block.device)
    cd_id=$($oa_hal_get --udi $i --key block.storage_device)
    cd_product=$($oa_hal_get --udi $i --key storage.model)
    cd_block=$($oa_hal_get --udi $i --key block.device)
    echo "optical^^^$cd_product^^^$cd_path^^^$cd_id^^^" >> $ReportFile
  done
fi

###################################
#       Volume Information        #
###################################

OA_Trace "Volumes..."

volume_all=$($oa_df -l -P -T -x tmpfs -B MB | $oa_awk '/^\//{print $0}')

if [ -z "$oa_hal_missing" ]; then
  for i in $($oa_hal_find --key info.category --string volume); do
    volume_type=$($oa_hal_get --udi $i --key volume.fstype)
    volume_parent=$($oa_hal_get --udi $i --key info.parent)
    volume_udi=$($oa_hal_get --udi $i --key info.udi)
    volume_mounted=$($oa_hal_get --udi $i --key volume.is_mounted)
    volume_uuid=$($oa_hal_get --udi $i --key volume.uuid)
    volume_path=$($oa_hal_get --udi $i --key block.device)
    volume_format=$($oa_hal_get --udi $i --key volume.fstype)
    volume_path_fmt=$(echo "$volume_path" | $oa_awk '{gsub("/", "\\/", $1); print $1}' 2> /dev/null)
    volume_size=$(echo "$volume_all" | $oa_awk '/^'"$volume_path_fmt"'/{print $3}')
    volume_description=$(echo "$volume_all" | $oa_awk '/^'"$volume_path_fmt"'/{print $7}')

    if [ "$volume_mounted" = "true" ]; then
      volume_mount_point=$($oa_hal_get --udi $i --key volume.mount_point)
    else
      volume_mount_point=""
    fi

    if [ "$volume_mount_point" = "/" ]; then
      volume_bootable='Yes'
    else
      volume_bootable='No'
    fi

    # volume_label=$($oa_hal_get --udi $i --key volume.label)
    volume_percent_used=$($oa_df $volume_path -l -P -T -B MB | $oa_awk '/^'"$volume_path_fmt"'/{print $6}')
    volume_free_space=$($oa_df $volume_path -l -P -T -B MB | $oa_awk '/^'"$volume_path_fmt"'/{print $5}')

    if [ "$volume_type" != "" ] && [ "$volume_type" != "swap" ]; then
      echo "partition^^^$volume_bootable^^^$volume_bootable^^^$volume_uuid^^^$volume_parent^^^$volume_udi^^^$volume_percent_used^^^$volume_bootable^^^$volume_path^^^$volume_format^^^$volume_free_space^^^$volume_size^^^$volume_description^^^" >> $ReportFile
    fi
  done
else
  for i in $(echo "$volume_all" | $oa_awk '{gsub("/", "\\/", $1); print $1}' 2> /dev/null); do
    volume_type=$(echo "$volume_all" | $oa_awk '/'"$i"'/{print $2}')
    volume_size=$(echo "$volume_all" | $oa_awk '/^'"$i"'/{print $3}')
    volume_path=$(echo "$volume_all" | $oa_awk '/'"$i"'/{print $1}')
    volume_format=$(echo "$volume_all" | $oa_awk '/'"$i"'/{print $2}')
    volume_description=$(echo "$volume_all" | $oa_awk '/^'"$i"'/{print $7}')
    volume_udi=$($oa_udev_info -q env -n $volume_path | $oa_awk '$1 ~ /ID_PATH=/{split($1,a,"="); print a[2]}')
    volume_uuid=$($oa_udev_info -q env -n $volume_path | $oa_awk '$1 ~ /FS_UUID=/{split($1,a,"="); print a[2]}')
    volume_parent=$($oa_udev_info -q env -n $volume_path | $oa_awk '$1 ~ /ID_SERIAL_SHORT=/{split($1,a,"="); print a[2]}')

    if [ "$(echo "$volume_all" | $oa_awk '/'"$i"'/{print $7}')" ]; then
      volume_mounted="True"
      volume_mount_point=$(echo "$volume_all" | $oa_awk '/'"$i"'/{print $7}')
      if [ "$volume_mount_point" = "/" ]; then
        volume_bootable='Yes'
      else
        volume_bootable='No'
      fi
    else
      volume_mounted="False"
      volume_mount_point=""
    fi

    volume_percent_used=$($oa_df $volume_path -l -P -T -B MB | $oa_awk '/^'"$i"'/{print $6}')
    volume_free_space=$($oa_df $volume_path -l -P -T -B MB | $oa_awk '/^'"$i"'/{print $5}')

    if [ "$volume_type" != "" ] && [ "$volume_type" != "swap" ]; then
      echo "partition^^^$volume_bootable^^^$volume_bootable^^^$volume_uuid^^^$volume_parent^^^$volume_udi^^^$volume_percent_used^^^$volume_bootable^^^$volume_path^^^$volume_format^^^$volume_free_space^^^$volume_size^^^$volume_description^^^" >> $ReportFile
    fi
  done
fi

###################################
#      Pagefile Information       #
###################################

OA_Trace "Pagefile..."

for i in $($oa_fdisk -l | $oa_awk '/Linux swap/{print $1}'); do
  oa_page_path="$i"
  oa_page_volume_size=$($oa_fdisk -l $i 2> /dev/null | $oa_awk -F"[:,]" '/^Disk \//{split($2,a," "); print a[1]}')
  oa_page_current_size=$($oa_df $i -B MB 2> /dev/null | $oa_sed '/^File/d' | $oa_awk '{print $3}')
  
  echo "pagefile^^^$oa_page_path^^^$oa_page_current_size^^^$oa_page_volume_size^^^" >> $ReportFile
done

###################################
#      Keyboard Information       #
###################################

OA_Trace "Keyboards..."

if [ -z "$oa_hal_missing" ]; then
  for i in $($oa_hal_cap --capability input.keyboard); do
    keyboard_caption=$($oa_hal_get --udi $i --key input.xkb.model 2> /dev/null)
    keyboard_description=$($oa_hal_get --udi $i --key input.product)
    keyboard_deviceid=$($oa_hal_get --udi $i --key input.device)
    echo "keyboard^^^$keyboard_caption^^^$keyboard_description^^^$keyboard_deviceid^^^" >> $ReportFile
  done
fi

###################################
#        Mouse Information        #
###################################

OA_Trace "Mice..."

if [ -z "$oa_hal_missing" ]; then
  for i in $($oa_hal_cap --capability input.mouse); do
    if $oa_lshal --long --show $i | $oa_hal_get --udi $i --key input.originating_device > /dev/null 2>&1; then
      mouse_parent=$($oa_hal_get --udi $i --key input.originating_device)
      mouse_description=$($oa_hal_get --udi $i --key input.product)
      mouse_deviceid=$($oa_hal_get --udi $i --key input.device)
      mouse_port=$($oa_hal_get --udi $mouse_parent --key info.subsystem)
      echo "mouse^^^$mouse_description^^^$mouse_number_of_buttons^^^$mouse_deviceid^^^$mouse_type^^^$mouse_port^^^" >> $ReportFile
    fi
  done
fi

###################################
#       Battery Information       #
###################################

OA_Trace "Battery..."

if [ -z "$oa_hal_missing" ]; then
  for i in $($oa_hal_find --key info.category --string battery); do
    battery_vendor=$($oa_hal_get --udi $i --key battery.vendor)
    battery_model=$($oa_hal_get --udi $i --key battery.model)
    battery_technology=$($oa_hal_get --udi $i --key battery.technology)
    battery_type=$($oa_hal_get --udi $i --key battery.type)
    battery_description="$battery_vendor - $battery_model"
    battery_id="$battery_type - $battery_technology"
    echo "battery^^^$battery_description^^^$battery_id^^^" >> $ReportFile
  done
elif [ -z "$oa_dmidecode_missing" ]; then
  for i in $($oa_dmidecode -t 22 | $oa_sed 's/^[ \t]*//g' | $oa_awk '/^Handle/{print $2}'); do 
    battery_info=$($oa_dmidecode -t 22 | $oa_sed -n '/^Handle '"$i"'/,/^$/p')
    battery_description=$(echo "$battery_info" | $oa_awk '/^Name:/{for (u=2; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    battery_id=$(echo "$battery_info" | $oa_awk '/^SBDS Chemistry:/{for (u=3; u<=NF; u++){printf("%s ", $u)}printf("\n")}')
    echo "battery^^^$battery_description^^^$battery_id^^^" >> $ReportFile
  done
fi

###################################
#        Users Information        #
###################################

OA_Trace "Users..."

for i in $($oa_awk -F":" '{print $1}' /etc/passwd); do
  oa_user="$i"
  oa_user_name="$($oa_awk -F":" '$1 ~ /^'"$i"'$/{print $5}' /etc/passwd)"
  oa_user_id="$($oa_awk -F":" '$1 ~ /^'"$i"'$/{print $3}' /etc/passwd)"
  oa_user_pass_expires=$($oa_chage -l $oa_user 2> /dev/null | $oa_awk '/^Password expires/{for (u=4; u<=NF; u++){printf("%s ", $u)}printf("\n")}')

  if [ -e /etc/shadow ]; then
    oa_user_file="/etc/shadow"
  else
    oa_user_file="/etc/passwd"
  fi

  # Check for disabled/locked accounts
  if [ "$($oa_awk -F":" '$1 ~ /'"$oa_user"'/ && $2 ~ /^(!|\*)/ {print $1}' $oa_user_file)" ]; then
    oa_user_disabled="Yes"
  else
    oa_user_disabled="No"
  fi

  # Check for accounts without passwords
  if [ "$($oa_awk -F: '$1 ~ /^'"$oa_user"'$/ && $2 ~ /^$/{print $1}' $oa_user_file)" ]; then
    oa_user_pass="False"
  else
    oa_user_pass="True"
  fi

  # Check if the password is changeable or not
  if [ -e /etc/shadow ] && [ "$($oa_chage -l $oa_user 2> /dev/null | $oa_awk -F":" '/(^Max|^Min)/{if ($2 != 0) print $2;}')" ]; then
    oa_user_pass_change="True"
  else
    oa_user_pass_change="False"
  fi

  echo "l_user^^^ ^^^$oa_user_disabled^^^$oa_user_name^^^$oa_user^^^$oa_user_pass_change^^^$oa_user_pass_expires^^^$oa_user_pass^^^$oa_user_id^^^" >> $ReportFile
done

###################################
#       Crontab Information       #
###################################

OA_Trace "Crontab..."

if [ -e /etc/crontab ]; then 
  #  Pull each line in the crontabs file without the extra lines and number them
  #+ so we can loop through it easy and hit each line
  #  The sed part is needed to avoid shell issues when sending the data with wget.
  #+ Is there anyway to avoid using this?
  cron_sys_dump=$($oa_awk '$1 ~ /([0-9]+|\*)/{print $0}' /etc/crontab | $oa_sed 's/&&/AND/g;s/||/OR/g' | nl)

  # Parse System Cron Jobs
  for i in $(echo "$cron_sys_dump" | $oa_awk '{print $1}'); do
    cron_line=$(echo "$cron_sys_dump" | $oa_awk '$1 ~ '"$i"' {print $0}') 
    oa_sched_creator="System Cron Job"
    oa_sched_taskname="System Cron Job #$i"
    oa_sched_runasuser=$(echo "$cron_line" | $oa_awk '{print $7}')
    oa_sched_tasktorun=$(echo "$cron_line" | $oa_awk '{for (u=8; u<=NF; u++){printf("%s ", $u)}printf("\n")}')

    echo "sched_task^^^ $oa_sched_taskname ^^^ $oa_sched_nextruntime ^^^ $oa_sched_status ^^^ $oa_sched_lastruntime ^^^ $oa_sched_lastresult ^^^ $oa_sched_creator ^^^ $oa_sched_schedule ^^^ $oa_sched_tasktorun ^^^ $oa_sched_taskstate ^^^ $oa_sched_runasuser ^^^" >> $ReportFile 
  done
fi

# Parse User Cron Jobs
for j in $($oa_awk -F: '{print $1}' /etc/passwd); do
  if [ "$($oa_crontab -u $j -l 2> /dev/null)" ]; then
    cron_user_dump=$($oa_crontab -u $j -l | $oa_awk '$1 ~ /([0-9]+|\*|\@)/{print $0}' | $oa_sed 's/&&/AND/g;s/||/OR/g' | nl)
    for i in $(echo "$cron_user_dump" | $oa_awk '{print $1}'); do
      cron_line=$(echo "$cron_user_dump" | $oa_awk '$1 ~ '"$i"' {print $0}') 
      oa_sched_creator="User : $j"
      oa_sched_taskname="User \"$j\" Cron Job #$i"
      oa_sched_runasuser="$j"
      oa_sched_tasktorun=$(echo "$cron_line" | $oa_awk '{for (u=7; u<=NF; u++){printf("%s ", $u)}printf("\n")}')

      echo "sched_task^^^ $oa_sched_taskname ^^^ $oa_sched_nextruntime ^^^ $oa_sched_status ^^^ $oa_sched_lastruntime ^^^ $oa_sched_lastresult ^^^ $oa_sched_creator ^^^ $oa_sched_schedule ^^^ $oa_sched_tasktorun ^^^ $oa_sched_taskstate ^^^ $oa_sched_runasuser ^^^" >> $ReportFile 
    done
  fi
done

###################################
#       Groups Information        #
###################################

OA_Trace "Groups..."

for i in $($oa_cat /etc/group); do
  oa_group_name=$(echo $i | $oa_cut -d":" -f1)
  oa_group_id=$(echo $i | $oa_cut -d":" -f3)
  oa_group_users=$(echo $i | $oa_cut -d":" -f4)

  echo "l_group^^^^^^$oa_group_name^^^$oa_group_users^^^$oa_group_id^^^" >> $ReportFile
done

###################################
#      Environment Variables      #
###################################

OA_Trace "Environment Variables..."

for i in $(env); do
  oa_env_name=$(echo $i | $oa_cut -d"=" -f1)
  oa_env_value=$(echo $i | $oa_cut -d"=" -f2)
  echo "env_var^^^$oa_env_name^^^$oa_env_value^^^" >> $ReportFile
done

###################################
#       Log File Information      #
###################################

OA_Trace "Log Files..."

for i in $($oa_find /var/log/ -type f | $oa_grep -Ev "(\.gz$|\.b?zip$|\.tar$|packages\/|scripts\/)" | $oa_sort); do
  log_file_size=$(ls -lh --block-size=KB "$i" | $oa_awk '{print $5}')
  log_name=$(echo "$i" | $oa_awk 'BEGIN{FS = "\/"}; {print $NF}' 2> /dev/null)
  log_file_name="$i"
  if [ "$log_file_size" != "0kB" ]; then
    echo "evt_log^^^ $log_name ^^^ $log_file_name ^^^ $log_file_size ^^^ ^^^ ^^^" >> $ReportFile
  fi
done

# TODO: The max size and the overwrite policy can be found in logrotate.conf. How to parse it?
# Missing - Max Size
#         - Overwrite Policy

###################################
#          Mapped Drives          #
###################################

OA_Trace "Mapped Drives..."

for i in $($oa_awk '/( cifs | nfs | smbfs )/{gsub("/", "\\/", $1); gsub(/\$/, "\\\$", $1); print $1}' /etc/mtab 2> /dev/null); do
  oa_mapped_type=$($oa_awk '/^'"$i"'/{print $3}' /etc/mtab)
  oa_mapped_id=$($oa_awk '/^'"$i"'/{print $1}' /etc/mtab)
  oa_mapped_filesystem=$($oa_awk '/^'"$i"'/{print $2}' /etc/mtab)
  oa_mapped_options=$($oa_awk '/^'"$i"'/{print $4}' /etc/mtab)

  # Check for a username in the mtab entry
  if $oa_grep -qE '^'"$i"'.*(user=|username=)' /etc/mtab; then
    oa_mapped_username=$($oa_awk 'BEGIN { IGNORECASE = 1 }/^'"$i"'/{match($4,"user(name)?=[^, \t]+"); tmp = substr($4, RSTART, RLENGTH); split(tmp, a, "="); print a[2]}' /etc/mtab)
  else
    oa_mapped_username=$net_user_name
  fi

  echo "mapped^^^$oa_mapped_filesystem^^^$oa_mapped_type^^^ ^^^$oa_mapped_id^^^ ^^^$oa_mapped_username^^^$oa_connected_as^^^" >> $ReportFile
done

###################################
#      IP Routes Information      #
###################################

OA_Trace "IP Routes..."
for i in $($oa_route | $oa_sed 's/  */,/g;/^Kernel/d;/^Destination/d'); do
  oa_ip_destination=$(echo $i | $oa_cut -d"," -f1)
  oa_ip_type=$(echo $i | $oa_cut -d"," -f8)
  oa_ip_mask=$(echo $i | $oa_cut -d"," -f3)
  oa_ip_metric1=$(echo $i | $oa_cut -d"," -f5)
  oa_ip_nexthop=$(echo $i | $oa_cut -d"," -f2)

  echo "ip_route^^^$oa_ip_destination^^^$oa_ip_mask^^^$oa_ip_metric1^^^$oa_ip_nexthop^^^$oa_ip_protocol^^^$oa_ip_type^^^" >> $ReportFile
done

###################################
#   System Software Information   #
###################################

#  What software would it make sense to include here? Possibly a var like OA_PACKAGES
#+ with default packages but modifiable by the user.
# OA_Trace "System Software Info..."

# "software^^^$system_app_name^^^$system_app_version^^^ ^^^ ^^^osinstall^^^$system_app_provider^^^ ^^^ ^^^$system_app_webpage" >> $ReportFile
 
###################################
# End - Submit to OA if specified #
###################################

OA_Audit_Log "" "log_end" "" "$SECONDS"
OA_Trace "Elapsed time of script: $($oa_date -d "00:00:00 $SECONDS seconds" +%Hh%Mm%Ss)"

if [ "$online" = "yesxml" ] || [ "$online" = "ie" ]; then
  if [ -z "$oa_wget_missing" ]; then
    echo ""
    OA_Trace "Submitting Information..."
   
    #  If our wget supports relaxed certificates rules, use that -- will let us use private HTTPS servers
    #+ with self-signed cerficates, such as XAMPP-type setups.
    if $oa_wget --help | $oa_grep -q '\--no-check-certificate'; then
      oa_wget_certificates="--no-check-certificate"
    fi

    $oa_sed -i '1s/^/submit=submit\&add=/' "$ReportFile"
    $oa_wget $oa_wget_certificates --delete-after --post-file="$ReportFile" $non_ie_page
    $oa_rm "$ReportFile"
    echo ""
    OA_Trace "Audit report submitted, check above wget output to confirm."
    echo ""
  else
    echo ""
    echo "Missing wget. See '$ReportFile' and submit manually."
    echo ""
  fi
else
  echo ""
  OA_Trace "Results have been stored in file '$ReportFile'."
  echo ""
fi

