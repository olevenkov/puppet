import 'puppetlabs_mysql/**/*'

# These will eventually be replaced with the puppet my.cnf template ====
# Begin .
class mysql::oldconfig {
  file {   "/etc/my.cnf":
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => [ "puppet:///modules/mysql/my.cnf.${hostname}" ],
  }
}

class mysql::oldconfignpgmysql2 {
  file {   "/var/lib/mysql/my.cnf":
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => [ "puppet:///modules/mysql/my.cnf.${hostname}" ],
  }
}

class mysql::oldconfignpgmysql1 {
  file {   "/usr/local/polopoly/mysql/my.cnf":
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => [ "puppet:///modules/mysql/my.cnf.${hostname}" ],
  }
}

class mysql::oldconfigstagingpolopoly {
  file {   "/usr/local/polopoly/mysql/my.cnf":
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => [ "puppet:///modules/mysql/my.cnf.staging-polopoly" ],
  }
}

class mysql::oldconfigstagingoctopus {
  file {   "/var/lib/mysql/etc/my.cnf":
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => [ "puppet:///modules/mysql/my.cnf.${hostname}" ],
  }
}


# ============================================= MYSQLD_MULTI ============================================

class mysql::multi {
  file {   "/usr/bin/mysqlmulti":
    owner   => "root",
    group   => "root",
    mode    => 755,
    source  => [ "puppet:///modules/mysql/mysqlmulti" ],
  }

  file {   "/var/lib/mysql/multi_my.cnf":
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => [ "puppet:///modules/mysql/multi_my.cnf.${hostname}" ],
  }

  file {   "/etc/init.d/mysqld_multi":
    owner   => "root",
    group   => "root",
    mode    => 755,
    source  => [ "puppet:///modules/mysql/mysqld_multi" ],
  }

  file {   "/etc/my.cnf":
    owner   => "root",
    group   => "root",
    mode    => 644,
    source  => [ "puppet:///modules/mysql/my.cnf.${hostname}" ],
  }
}

class mysql::multi1 {
  file {   "/etc/init.d/mysql_1":
    owner   => "root",
    group   => "root",
    mode    => 755,
    source  => [ "puppet:///modules/mysql/mysql_1" ],
  }
}

class mysql::multi2 {
  file {   "/etc/init.d/mysql_2":
    owner   => "root",
    group   => "root",
    mode    => 755,
    source  => [ "puppet:///modules/mysql/mysql_2" ],
  }
}

class mysql::multi3 {
  file {   "/etc/init.d/mysql_3":
    owner   => "root",
    group   => "root",
    mode    => 755,
    source  => [ "puppet:///modules/mysql/mysql_3" ],
  }
}

# ============================================= MY.CNF ============================================

class mysql::baseconfig {

	# Base my.cnf Configuration
	# Commented Values are File Defaults
	# $port="3306"
        # $socket="/var/run/mysql/mysql.sock"
        # $pid_file="/var/run/mysql/mysqld.pid"
        # $datadir="/var/lib/mysql/data"
        # $basedir="/var/lib/basedir"
	# $tmpdir="/tmp"
	# $oldpasswords="1"
        # $skip_name_resolve="true"
        # $lower_case_table_names="true"
        # $skip_networking="true"
	# $skip_bdb="true"
        # $log_bin_trust_function_creators="1"
        # $default_storage_engine="InnoDB" # or MyISAM
        # $default_table_type="InnoDB"
	# $ft_min_word_len="ft min word lenngth"
        # $ft_max_word_len="ft max word length"
	# $slow_query_log="1"
        # $slow_query_log_file="/var/lib/mysql/logs/slow/mysql-slow.log"
	# $log_slow_queries="/var/lib/mysql/logs/slow/mysql-slow.log" # DEPRECIATED. Use slow_query_log_file
        # $long_query_time="1"
        # $log_queries_not_using_indexes="true"
        # $log="true"
        # $log_error="/var/lib/mysql/logs/error/mysql-errors.err"
        # $log_warnings="log warnings"
	# $max_connections="800"
        # $max_connect_errors="max connect errors"
        # $table_cache="1024"
        # $thread_cache_size="100"
        $wait_timeout="300"
        # $back_log="back log"
        # $read_buffer_size="128K"
        # $read_rnd_buffer_size="8M"
        # $sort_buffer_size="100M"
        # $join_buffer_size="512M"
        $max_allowed_packet="32M"
        # $thread_stack="512K"
        # $binlog_cache_size="1M"
        # $bulk_insert_buffer_size="64M"
        # $log_bin="/var/lib/mysql/logs/bin/mysql-bin"
	# $binlog_format="ROW"
        # $binlog_ignore_db="binlog_ignore_db = \"mysql\""
	# $binlog_do_db="binlog_do_db = \"mysql\""
        # $max_binlog_size="max binlog size"
        # $expire_logs_days="8"
        # $sync_binlog="1"
        # $replicate_ignore_db="replicate_ignore_db = \"DATABASE\""
	# $replicate_do_db="replicate_do_db = \"DATABASE\""
        # $read_only="true"
        # $relay_log="/var/lib/mysql/logs/relay/relay-log"
        # $max_relay_log_size="max relay log size"
        # $slave_skip_errors="1062,1053"
        # $log_slave_updates="true"
        # $server_id="123" # select inet_aton('127.0.0.1')
        # $query_cache_size="512M"
        # $query_cache_limit="2M"
        # $key_buffer="512M"
        # $query_cache_min_res_unit="2048"
        # $delay_key_write="OFF"
        # $myisam_sort_buffer_size="256M"
        # $myisam_max_sort_file_size="5G"
        # $myisam_repair_threads="2"
        # $myisam_recover="true"
        # $tmp_table_size="512M"
        # $max_heap_table_size="512M"
        # $max_join_size="4096M"
        # $skip_innodb="true"
        # $innodb_support_xa="true" #Should remain disabled
	# $transaction_isolation="REPEATABLE-READ"
	# $innodb_file_per_table="true"
	# $innodb_additional_mem_pool_size="20M"
        # $innodb_flush_log_at_trx_commit="2"
        # $innodb_log_buffer_size="8M"
        # $innodb_buffer_pool_size="2G"
        # $innodb_log_file_size="256M"
        # $innodb_data_file_path="ibdata1:500M:autoextend"
        # $innodb_flush_method="O_DIRECT"
        # $innodb_thread_concurrency="32"
        $innodb_data_home_dir="/var/lib/mysql/data/"
        $innodb_log_group_home_dir="/var/lib/mysql/data/"
        # $innodb_file_io_threads="file IO threads"
        # $innodb_lock_wait_timeout="lock wait timeout"
        # $innodb_log_files_in_group="log files in group"
        # $innodb_max_dirty_pages_pct="max dirty pages"
        $mysqldump_max_allowed_packet="128M"
        $open_files_limit="8192"
        $no_auto_rehash="true"
}

# Used for Maximum Performance and inheriting classes only
class mysql::maxbaseconfig inherits mysql::baseconfig {

        $max_connections="1500"
        $table_cache="1024"
        $thread_cache_size="100"
        $wait_timeout="300"
        $read_buffer_size="128K"
        $read_rnd_buffer_size="8M"
        $sort_buffer_size="100M"
        $join_buffer_size="512M"
        $max_allowed_packet="32M"
        $thread_stack="512K"
        $binlog_cache_size="1M"
        $bulk_insert_buffer_size="64M"
        $query_cache_size="512M"
        $query_cache_limit="2M"
        $key_buffer="512M"
        $query_cache_min_res_unit="2048"
        $delay_key_write="OFF"
        $myisam_sort_buffer_size="256M"
        $myisam_max_sort_file_size="5G"
        $myisam_repair_threads="2"
        $myisam_recover="true"
        $tmp_table_size="512M"
        $max_heap_table_size="512M"
        $max_join_size="4096M"
        $innodb_additional_mem_pool_size="20M"
        $innodb_flush_log_at_trx_commit="2"
        $innodb_log_buffer_size="8M"
        $innodb_buffer_pool_size="2G"
        $innodb_log_file_size="256M"
        $innodb_data_file_path="ibdata1:500M:autoextend"
        $innodb_flush_method="O_DIRECT"
        $innodb_thread_concurrency="32"
}

# prod-blogs-sa-db
class mysql::config-prodblogssadb inherits mysql::maxbaseconfig {

	$socket="/var/run/mysqld/mysql.sock"
        $pid_file="/var/run/mysqld/mysqld.pid"
        $datadir="/var/lib/mysql/data"
	$log_slow_queries="/var/lib/mysql/logs/slow/mysql-slow.log"
	$wait_timeout="60"
	$long_query_time="1"
        $log_queries_not_using_indexes="true"
	$log_error="/var/lib/mysql/logs/error/mysql-errors.err"
	$skip_innodb="true"
	$default_storage_engine="MyISAM"
        $default_table_type="MyISAM"
	$log_bin="/var/lib/mysql/logs/bin/mysql-bin"
        $expire_logs_days="1"
        $server_id="12"
	$myisam_recover="true"

        file { "/var/lib/mysql/etc/my.cnf":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/my.cnf.erb"),
        }
}

# test-ed-mysql
class mysql::config-testedmysql inherits mysql::maxbaseconfig {

        # my.cnf settings
	$skip_name_resolve="true"
	$log_bin_trust_function_creators="true"
	$ft_min_word_len="3"
        $ft_max_word_len="50"
	$slow_query_log="1"
        $slow_query_log_file="/var/lib/mysql/logs/slow/mysql-slow.log"
        $long_query_time="1"
        $log_queries_not_using_indexes="true"

        file { "/var/lib/mysql/etc/my.cnf":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/my.cnf.erb"),
        }
}

# staging-ed-mysql
class mysql::config-stagingedmysql inherits mysql::maxbaseconfig {

	$skip_name_resolve="true"
        $log_bin_trust_function_creators="true"
        $ft_min_word_len="3"
        $ft_max_word_len="50"
        $slow_query_log="1"
        $slow_query_log_file="/var/lib/mysql/logs/slow/mysql-slow.log"
        $long_query_time="1"
        $log_queries_not_using_indexes="true"
	# $server_id="3232258233"

        file { "/var/lib/mysql/etc/my.cnf":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/my.cnf.erb"),
        }

}

# stagingmysql (OLD)
class mysql::config-stagingmysql inherits mysql::baseconfig {

        $socket="/usr/local/mysql/mysql.sock"
        $datadir="/usr/local/mysql"
	$pid_file="/usr/local/mysql/stagingmysql.nature.com.pid"
        $basedir="/usr"
        $log_bin_trust_function_creators="1"
        $default_storage_engine="MYISAM" # or MyISAM
        $default_table_type="MYISAM"
        $ft_min_word_len="3"
        $ft_max_word_len="84"
        $slow_query_log="1"
        $slow_query_log_file="stagingmysql.slowlog"
        # $log_slow_queries="/var/lib/mysql/logs/slow/mysql-slow.log" # DEPRECIATED. Use slow_query_log_file
        $long_query_time="1"
        $log_queries_not_using_indexes="true"
        $log_error="stagingmysql.err"
        $log_warnings="2"
        $max_connections="600"
        # $max_connect_errors="max connect errors"
        $table_cache="512"
        $thread_cache_size="100"
        $wait_timeout="300"
        # $back_log="back log"
        $read_buffer_size="128K"
        $read_rnd_buffer_size="4M"
        $sort_buffer_size="100M"
        $join_buffer_size="512M"
        $max_allowed_packet="64M"
        $binlog_cache_size="1M"
        $bulk_insert_buffer_size="64M"
        $query_cache_size="256M"
        $query_cache_limit="2M"
        $key_buffer="256M"
        $query_cache_min_res_unit="2048"
        $delay_key_write="OFF"
        $myisam_sort_buffer_size="256M"
        $myisam_max_sort_file_size="5G"
        $myisam_repair_threads="2"
        $myisam_recover="true"
        $tmp_table_size="256M"
        $max_heap_table_size="256M"
        $max_join_size="4096M"
        # $innodb_support_xa="true" #Should remain disabled
        # $transaction_isolation="REPEATABLE-READ"
        # $innodb_file_per_table="true"
        $innodb_additional_mem_pool_size="16M"
        $innodb_flush_log_at_trx_commit="2"
        $innodb_log_buffer_size="8M"
        $innodb_buffer_pool_size="1G"
        $innodb_log_file_size="128M"
        $innodb_data_file_path="ibdata1:10M:autoextend"
        # $innodb_flush_method="O_DIRECT"
        $innodb_thread_concurrency="20"
        $innodb_lock_wait_timeout="120"
        $innodb_log_files_in_group="2"
        $innodb_max_dirty_pages_pct="90"
	$innodb_data_home_dir="/usr/local/mysql/"
        $innodb_log_group_home_dir="/usr/local/mysql/"
        $mysqldump_max_allowed_packet="128M"
        $open_files_limit="8192"
        $no_auto_rehash="true"

        #file { "/etc/my.cnf":
        #        owner => "root",
        #        group => "root",
        #        mode  => 644,
        #        content => template("mysql/my.cnf.erb"),
        #}
}

# spider my.cnf
class mysql::config-spider inherits mysql::maxbaseconfig {

        $oldpasswords="1"
        $slow_query_log="1"
        $slow_query_log_file="/var/lib/mysql/logs/slow/mysql-slow.log"
        $long_query_time="1"
        $log_queries_not_using_indexes="true"
        $log_bin="/var/lib/mysql/logs/bin/mysql-bin"
        $binlog_format="ROW"
	$max_binlog_size="500M"
	$max_join_size="18446744073709551615"
	$expire_logs_days="3"
        # $server_id="123"
	$innodb_file_per_table="true"
	$transaction_isolation="READ-COMMITTED"
        $innodb_additional_mem_pool_size="16M"
        $innodb_log_buffer_size="1048576"

        file { "/var/lib/mysql/etc/my.cnf":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/my.cnf.erb"),
        }
}

# my.cnf - npgmysql4
class mysql::config-npgmysql4 inherits mysql::maxbaseconfig {

        $pid_file="/var/lib/mysql/data/npgmysql4.nature.com.pid"
	$log_warnings="2"
	$skip_name_resolve="true"
        $log_bin_trust_function_creators="1"
	$lower_case_table_names="1"
	$expire_logs_days="8"
        $ft_min_word_len="3"
        $ft_max_word_len="84"
        $slow_query_log="1"
	$log_bin="/var/lib/mysql/logs/bin/mysql-bin"
        $slow_query_log_file="/var/lib/mysql/logs/slow/mysql-slow.log"
        $long_query_time="1"
        $log_queries_not_using_indexes="true"
	$server_id="3232236780" # select inet_aton('127.0.0.1')
	$innodb_buffer_pool_size="4G"
	$innodb_file_io_threads="4"
        $innodb_lock_wait_timeout="120"
        $innodb_log_files_in_group="2"
        $innodb_max_dirty_pages_pct="90"

        file { "/var/lib/mysql/etc/my.cnf":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/my.cnf.erb"),
        }
}

# Remove this shortly
class mysql::testconfig inherits mysql::baseconfig {

        # my.cnf settings (in order presented in template)
	$max_connections="500"
	$max_allowed_packet="64M"

        file { "/home/sadams/my.cnf.test":
                owner => "sadams",
                group => "sadams",
                mode  => 644,
                content => template("mysql/my.cnf.erb"),
        }
}

# Reserved for new servers
class mysql::env {

	file {   "/etc/my.cnf":
	   owner   => "root",
	   group   => "root",
	   mode    => 644,
	   source  => [ "puppet:///modules/mysql/my.cnf.${hostname}" ],
  	}
}


# ============================================= BACKUPS ============================================

# Base Backup
class mysql::basebackup {

	# Base Backup Settings
	# Commented Values are mostly file defaults
        # $backuplocation="/var/lib/mysql/backups" # Default
        # $tmpdir="/var/lib/mysql/tmp" # Default
        # $backuptype=3  # (1) SQL Dump (2) File Copy (3) Both # Default
        $myusername="dbbackup"
        $mypassword="dbbackup"
        # $myhost="localhost" # Default
        # $myport="3306"  # Default
        # $mysqlbasedir="/var/lib/mysql/" # Default
        # $mysqlstartupcmd="/sbin/service mysql start" # Default
        # $mysqlshutdowncmd="/sbin/service mysql stop" # Default
	# $mysqlbackupthesedirs="\"etc\" \"scripts\" \"logs/error\" \"logs/slow\"" # Default
        # $includebinlogfiles="/var/lib/mysql/nature/logs/bin"
        # includedatadir="true" # Restarts MySQL
        # $exportmyschema="true" # Include Full Schema backup as separate .sql # Default
        # $exportmygrants="true" #Export MySQL Grants Table
        # $exportcrontab="true"
        # $maxruntime="360" # Default
	# $maxfullbackuphours="2880" # Default
	# $keepdays=7 # Default
	# $weeklyrotate=0 # Default
	# $backupowner="root.root" # Default
	# $movetolocal="/home/sadams/tmp"
	$emailnotify="who-support@us.nature.com"
	# $databases=" \"mysql\" "
	# $alldatabases="true"
	# $ignoredbs="'mysql','performance_schema','information_schema'" # Default
	# $opt="true"
	# $completeinsert="true" # For Debugging
	# $skipquotenames="true"
	# $hexblob="true"
	# $nodata="true"
	# $singletransaction="true"
	# $ismaster="1" # 1 Master, 2 Slave
}

# prod-blogs-sa-db
class mysql::backup-prodblogssadb inherits mysql::basebackup {

        $myhost="localhost"
        $exportmyschema="true" # Include Full Schema backup as separate .sql
        $exportmygrants="true" #Export MySQL Grants Table
        $exportcrontab="true"
        $keepdays=3
        $weeklyrotate=0
	# $includebinlogfiles="/var/lib/mysql/logs/bin"
        # $movetolocal="/home/sadams/tmp"
        $emailnotify="s.adams@us.nature.com"
        $alldatabases="true"
        $opt="true"
        # $completeinsert="true" # For Debugging
        # $skipquotenames="true" #disabled for blogs. Causing Errors
        # $nodata="true"
        # $singletransaction="true"
        $ismaster="1" # 1 Master, 2 Slave

        file { "/var/lib/mysql/scripts/NightlyBackup.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

# staging-ed-mysql
class mysql::backup-stagingedmysql inherits mysql::basebackup {

	$myhost="localhost"
        $exportmyschema="true" # Include Full Schema backup as separate .sql
        $exportmygrants="true" #Export MySQL Grants Table
        $exportcrontab="true"
        $keepdays=3
        $weeklyrotate=0
        # $movetolocal="/home/sadams/tmp"
        $emailnotify="s.adams@us.nature.com"
        $alldatabases="true"
        $opt="true"
        # $completeinsert="true" # For Debugging
        $skipquotenames="true"
        # $nodata="true"
        $singletransaction="true"
        # $ismaster="1" # 1 Master, 2 Slave

	file { "/var/lib/mysql/scripts/NightlyBackup.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

# npgmysql4
class mysql::backup-npgmysql4 inherits mysql::basebackup {

        # Nightly Backup Settings
        $myhost="localhost"
        $includebinlogfiles="/var/lib/mysql/logs/bin"
	$singletransaction="true"
	$alldatabases="true"
        $movetolocal="/backups"
	$exportmyschema="true"
	$exportmygrants="true"
	$exportcrontab="true"
        $ismaster="1" # 1 Master, 2 Slave
	$keepdays=5
        # $nodata="true"

        file { "/var/lib/mysql/scripts/NightlyBackup.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}


class mysql::backup-test-and-staging-nature1 inherits mysql::basebackup {

        # Nightly Backup Settings
	$backuplocation="/var/lib/mysql/nature/backups"
	$tmpdir="/var/lib/mysql/nature/tmp"
	$myhost="127.0.0.1"
	$mysqlbasedir="/var/lib/mysql/nature"
	$mysqlstartupcmd="/sbin/service mysql_1 start"
	$mysqlshutdowncmd="/sbin/service mysql_1 stop"
	$alldatabases="true"
	$exportmyschema="true" # Include Full Schema backup as separate .sql
	$exportmygrants="true" #Export MySQL Grants Table
	$exportcrontab="true"
	# $singletransaction="true"
	$keepdays=3
	# $nodata="true"

        file { "/var/lib/mysql/nature/scripts/NightlyBackup.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

class mysql::backup-test-and-staging-nature2 inherits mysql::basebackup {

        # Nightly Backup Settings
        $backuplocation="/var/lib/mysql/polopoly/backups"
        $tmpdir="/var/lib/mysql/polopoly/tmp"
        $myhost="127.0.0.1"
        $myport="3307"
        $mysqlbasedir="/var/lib/mysql/polopoly"
        $mysqlstartupcmd="/sbin/service mysql_2 start"
        $mysqlshutdowncmd="/sbin/service mysql_2 stop"
        $alldatabases="true"
        $exportmyschema="true" # Include Full Schema backup as separate .sql
        $exportmygrants="true" #Export MySQL Grants Table
	$exportcrontab="true"
        $singletransaction="true"
        $keepdays=3
        # $nodata="true"

        file { "/var/lib/mysql/polopoly/scripts/NightlyBackup.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

class mysql::backup-rptmysql1 inherits mysql::basebackup {

        # Nightly Backup Settings
        $backuplocation="/var/lib/mysql/backups/nature"
        $backuptype=1  # (1) SQL Dump (2) File Copy (3) Both
        $myhost="127.0.0.1"
        $mysqlbasedir="/var/lib/mysql/data/nature"
        $mysqlstartupcmd="/sbin/service mysql_1 start"
        $mysqlshutdowncmd="/sbin/service mysql_1 stop"
        $alldatabases="true"
        $exportmyschema="true" # Include Full Schema backup as separate .sql
        $exportmygrants="true" #Export MySQL Grants Table
        $exportcrontab="true"
        $singletransaction="true"
        $keepdays=1
        $movetolocal="/backups/nature"
        # $nodata="true"
	$ismaster="2"

        file { "/var/lib/mysql/scripts/NightlyBackup-Nature.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

class mysql::backup-rptmysql2 inherits mysql::basebackup {

        # Nightly Backup Settings
        $backuplocation="/var/lib/mysql/backups/polopoly"
        $backuptype=1  # (1) SQL Dump (2) File Copy (3) Both
        $myhost="127.0.0.1"
        $myport="3307"
        $mysqlbasedir="/var/lib/mysql/data/polopoly"
        $mysqlstartupcmd="/sbin/service mysql_2 start"
        $mysqlshutdowncmd="/sbin/service mysql_2 stop"
        $alldatabases="true"
        $exportmyschema="true" # Include Full Schema backup as separate .sql
        $exportmygrants="true" #Export MySQL Grants Table
        $exportcrontab="true"
        $singletransaction="true"
        $keepdays=1
        $movetolocal="/backups/polopoly"
        # $nodata="true"
	$ismaster="2"

        file { "/var/lib/mysql/scripts/NightlyBackup-Polopoly.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

class mysql::backup-rptmysql3 inherits mysql::basebackup {

        # Nightly Backup Settings
        $backuplocation="/var/lib/mysql/backups/prod-blogs-sa-db"
        $backuptype=1  # (1) SQL Dump (2) File Copy (3) Both
        $myhost="127.0.0.1"
        $myport="3308"
        $mysqlbasedir="/var/lib/mysql/data/prod-blogs-sa-db"
        $mysqlstartupcmd="/sbin/service mysql_3 start"
        $mysqlshutdowncmd="/sbin/service mysql_3 stop"
        $alldatabases="true"
        $exportmyschema="true" # Include Full Schema backup as separate .sql
        $exportmygrants="true" #Export MySQL Grants Table
        $exportcrontab="true"
        $singletransaction="true"
        $keepdays=1
        $movetolocal="/backups/prod-blogs-sa-db"
        # $nodata="true"
	$ismaster="2"

        file { "/var/lib/mysql/scripts/NightlyBackup-ProdBlogs.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

# spider
class mysql::backup-spider inherits mysql::basebackup {

        # Nightly Backup Settings
        # $myhost="127.0.0.1"
        $alldatabases="true"
        $exportmyschema="true" # Include Full Schema backup as separate .sql
        $exportmygrants="true" #Export MySQL Grants Table
        $exportcrontab="true"
        $singletransaction="true"
        $keepdays=5
        $movetolocal="/var/confluence/backups"
        $skipquotenames="true"
	# $nodata="true"

        file { "/var/lib/mysql/scripts/NightlyBackup.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/NightlyBackup.erb"),
        }
}

# ============================================= LOG ROTATE ============================================

class mysql::baselogrotate {

	# $files="/var/lib/mysql/logs/error/mysql-errors.err /var/lib/mysql/logs/slow/mysql-slow.log"
	# $rotatedays="7"
	# $myflags="-h localhost -P 3306"

	file { "/etc/logrotate.d/mysql":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/logrotate.d-mysql.erb"),
        }
}

class mysql::logrotateslave1 {

        $files="/var/lib/mysql/logs/error/mysql-errors.err"
        # $rotatedays="7"
        # $myflags="-h localhost -P 3306"

	file { "/etc/logrotate.d/mysql":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/logrotate.d-mysql.erb"),
        }
}

class mysql::logrotatemulti1a {

        $files="/var/lib/mysql/nature/logs/slow/mysql-slow.log  /var/lib/mysql/nature/logs/error/mysql-errors.err"
        # $rotatedays="7"
        $myflags="-h 127.0.0.1 -P 3306"

        file { "/etc/logrotate.d/mysql1":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/logrotate.d-mysql.erb"),
        }
}

class mysql::logrotatemulti1b {

        $files="/var/lib/mysql/polopoly/logs/slow/mysql-slow.log  /var/lib/mysql/polopoly/logs/error/mysql-errors.err"
        # $rotatedays="7"
        $myflags="-h 127.0.0.1 -P 3307"

        file { "/etc/logrotate.d/mysql2":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/logrotate.d-mysql.erb"),
        }
}

class mysql::logrotatemulti2a {

        $files="/var/lib/mysql/logs/nature/error/mysql-errors.err"
        # $rotatedays="7"
        $myflags="-h 127.0.0.1 -P 3306"

        file { "/etc/logrotate.d/mysql1":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/logrotate.d-mysql.erb"),
        }
}

class mysql::logrotatemulti2b {

        $files="/var/lib/mysql/logs/polopoly/error/mysql-errors.err"
        # $rotatedays="7"
        $myflags="-h 127.0.0.1 -P 3307"

        file { "/etc/logrotate.d/mysql2":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/logrotate.d-mysql.erb"),
        }
}

class mysql::logrotatemulti2c {

        $files="/var/lib/mysql/logs/prod-blogs-sa-db/error/mysql-errors.err"
        # $rotatedays="7"
        $myflags="-h 127.0.0.1 -P 3308"

        file { "/etc/logrotate.d/mysql3":
                owner => "root",
                group => "root",
                mode  => 644,
                content => template("mysql/logrotate.d-mysql.erb"),
        }
}

# ============================================= LinuxUtil Push and Pull  ============================================

# linuxutil
class mysql::slowpushandpull
{
	file { "/var/lib/mysql/scripts/PullSlowLogs.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                source  => [ "puppet:///modules/mysql/PullSlowLogs.sh" ],
        }
}

# npgmysql1
class mysql::slowpushandpullnpgmysql1
{
        # $maxruntime="240" # Default
        $sourcehostname="npgmysql1"
        $sourceip="192.168.4.231"
        $sourcefiles="/usr/local/polopoly/slowlogs/*.*"
        $targetdir="/var/lib/mysql/SlowLogReports/npgmysql1/tmp"
        $targetremove="true" # Remove old files b4 starting run from $targetdir
        # $targetgunzip="true"
        $targetcat="true"
        $cleanuptargetdir="true" # Cleanup tmp files after run completes. Saves space
        $targetreportdest="/var/lib/mysql/SlowLogReports/npgmysql1"
        $copytowww="/var/www/html/SlowReports/npgmysql1"
        $downloadurl="http://192.168.4.40/SlowReports/npgmysql1"
        $anemometerhost="192.168.88.40"
        $anemometerun="anemometer"
        $anemometerpwd="superSecurePass"
        $anemometerdb="slow_npgmysql1"
        $anemometersourceip="192.168.4.231"
        $anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Polopoly%20(Production)"
        $emailnotify="\"s.adams@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-npgmysql1.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# npgmysql2
class mysql::slowpushandpullnpgmysql2
{
        $sourcehostname="npgmysql2"
        $sourceip="192.168.4.232"
        $sourcefiles="/var/lib/mysql/slowlogs/*.*"
        $targetdir="/var/lib/mysql/SlowLogReports/npgmysql2/tmp"
        $targetremove="true" # Remove old files b4 starting run from $targetdir
        # $targetgunzip="true"
        $targetcat="true"
        $cleanuptargetdir="true" # Cleanup tmp files after run completes. Saves space
        $targetreportdest="/var/lib/mysql/SlowLogReports/npgmysql2"
        $copytowww="/var/www/html/SlowReports/npgmysql2"
        $downloadurl="http://192.168.4.40/SlowReports/npgmysql2"
        $anemometerhost="192.168.88.40"
        $anemometerun="anemometer"
        $anemometerpwd="superSecurePass"
        $anemometerdb="slow_npgmysql2"
        $anemometersourceip="192.168.4.232"
        $anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Nature%20MySQL%20(Production)"
        $emailnotify="\"who-support@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-npgmysql2.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# npgmysql4
class mysql::slowpushandpullnpgmysql4
{
        # $maxruntime="240" # Default
	$sourcehostname="npgmysql4"
	$sourceip="192.168.4.237"
	$sourcefiles="/var/lib/mysql/logs/slow/*.*"
	$targetdir="/var/lib/mysql/SlowLogReports/npgmysql4/tmp"
	$targetremove="true" # Remove old files b4 starting run from $targetdir
	$targetgunzip="true"
	$targetcat="true"
	$cleanuptargetdir="true" # Cleanup tmp files after run completes. Saves space
	$targetreportdest="/var/lib/mysql/SlowLogReports/npgmysql4"
	$copytowww="/var/www/html/SlowReports/npgmysql4"
	$downloadurl="http://192.168.4.40/SlowReports/npgmysql4"
	$anemometerhost="192.168.88.40"
	$anemometerun="anemometer"
	$anemometerpwd="superSecurePass"
	$anemometerdb="slow_npgmysql4"
	$anemometersourceip="192.168.4.237"
	$anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Nature%20Education%20(Production)"
	$emailnotify="\"who-support@us.nature.com\" \"d.pandey@us.nature.com\" \"a.ghosh@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-npgmysql4.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# staging-ed-mysql
class mysql::slowpushandpullstagingedmysql
{
        $sourcehostname="staging-ed-mysql"
        $sourceip="192.168.88.185"
        $sourcefiles="/var/lib/mysql/logs/slow/*.*"
        $targetdir="/var/lib/mysql/SlowLogReports/staging-ed-mysql/tmp"
        $targetremove="true" # Remove old files b4 starting run from $targetdir
        $targetgunzip="true"
        $targetcat="true"
        $cleanuptargetdir="true" # Cleanup tmp files after run completes. Saves space
        $targetreportdest="/var/lib/mysql/SlowLogReports/staging-ed-mysql"
        $copytowww="/var/www/html/SlowReports/staging-ed-mysql"
        $downloadurl="http://192.168.4.40/SlowReports/staging-ed-mysql"
        $anemometerhost="192.168.88.40"
        $anemometerun="anemometer"
        $anemometerpwd="superSecurePass"
        $anemometerdb="slow_staging_ed_mysql"
        $anemometersourceip="192.168.88.185"
        $anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Nature%20Education%20(Staging)"
        $emailnotify="\"who-support@us.nature.com\" \"d.pandey@us.nature.com\" \"a.ghosh@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-stagingedmysql.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# test-ed-mysql
class mysql::slowpushandpulltestedmysql
{
        $sourcehostname="test-ed-mysql"
        $sourceip="192.168.88.186"
        $sourcefiles="/var/lib/mysql/logs/slow/*.*"
        $targetdir="/var/lib/mysql/SlowLogReports/test-ed-mysql/tmp"
        $targetremove="true" # Remove old files b4 starting run from $targetdir
        $targetgunzip="true"
        $targetcat="true"
        $cleanuptargetdir="true" # Cleanup tmp files after run completes. Saves space
        $targetreportdest="/var/lib/mysql/SlowLogReports/test-ed-mysql"
        $copytowww="/var/www/html/SlowReports/test-ed-mysql"
        $downloadurl="http://192.168.4.40/SlowReports/test-ed-mysql"
        $anemometerhost="192.168.88.40"
        $anemometerun="anemometer"
        $anemometerpwd="superSecurePass"
        $anemometerdb="slow_test_ed_mysql"
        $anemometersourceip="192.168.88.186"
        $anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Nature%20Education%20(Testing)"
        $emailnotify="\"who-support@us.nature.com\" \"d.pandey@us.nature.com\" \"a.ghosh@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-testedmysql.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# stagingmysql
class mysql::slowpushandpullstagingmysql
{
        $sourcehostname="stagingmysql"
        $sourceip="192.168.88.171"
        $sourcefiles="/usr/local/mysql/slowlogs/*.*"
        $targetdir="/var/lib/mysql/SlowLogReports/staging-mysql/tmp"
        $targetremove="true" # Remove old files b4 starting run from $targetdir
        # $targetgunzip="true"
        $targetcat="true"
        $cleanuptargetdir="true" # Cleanup tmp files after run completes. Saves space
        $targetreportdest="/var/lib/mysql/SlowLogReports/staging-mysql"
        $copytowww="/var/www/html/SlowReports/staging-mysql"
        $downloadurl="http://192.168.4.40/SlowReports/staging-mysql"
        $anemometerhost="192.168.88.40"
        $anemometerun="anemometer"
        $anemometerpwd="superSecurePass"
        $anemometerdb="slow_staging_mysql"
        $anemometersourceip="192.168.88.171"
        $anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Nature%20MySQL%20(Staging)"
        $emailnotify="\"s.adams@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-stagingmysql.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# test-nature-mysql
class mysql::slowpushandpulltestnaturemysql
{
        $sourcehostname="test-nature-mysql"
        $sourceip="192.168.88.196"
        $sourcefiles="/var/lib/mysql/nature/logs/slow/*.*"
        $targetdir="/var/lib/mysql/SlowLogReports/test-nature-mysql/tmp"
        $targetremove="true" # Remove old files b4 starting run from $targetdir
        $targetgunzip="true"
        $targetcat="true"
        $cleanuptargetdir="true" # Cleanup tmp files after run completes. Saves space
        $targetreportdest="/var/lib/mysql/SlowLogReports/test-nature-mysql"
        $copytowww="/var/www/html/SlowReports/test-nature-mysql"
        $downloadurl="http://192.168.4.40/SlowReports/test-nature-mysql"
        $anemometerhost="192.168.88.40"
        $anemometerun="anemometer"
        $anemometerpwd="superSecurePass"
        $anemometerdb="slow_test_nature_mysql"
        $anemometersourceip="192.168.88.196"
        $anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Nature%20MySQL%20(Testing)"
        $emailnotify="\"s.adams@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-testnaturemysql.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# spider
class mysql::slowpushandpullspider
{
        $sourcehostname="spider"
        $sourceip="192.168.88.30"
        $sourcefiles="/var/lib/mysql/logs/slow/*.*"
        $targetdir="/var/lib/mysql/SlowLogReports/spider/tmp"
        $targetremove="true"
        $targetgunzip="true"
        $targetcat="true"
        $cleanuptargetdir="true"
        $targetreportdest="/var/lib/mysql/SlowLogReports/spider/"
        $copytowww="/var/www/html/SlowReports/spider"
        $downloadurl="http://192.168.4.40/SlowReports/spider"
        $anemometerhost="192.168.88.40"
        $anemometerun="anemometer"
        $anemometerpwd="superSecurePass"
        $anemometerdb="slow_spider"
        $anemometersourceip="192.168.88.30"
        $anemometerlink="http://whoblog.nature.com/anemometer/index.php?action=report&datasource=Spider"
        $emailnotify="\"s.adams@us.nature.com\"" # Default

        file { "/var/lib/mysql/scripts/Pull-spider.sh":
                owner => "root",
                group => "root",
                mode  => 755,
                content => template("mysql/Pull-And-Analyze-SlowLogs.erb"),
        }
}

# ============================================= Env Settings ============================================


# Classes that just make Shaun's life easier :)
class mysql::baseshaunsenv {

	file { "/home/sadams/.vimrc":
                owner => "sadams",
                group => "sadams",
                mode  => 644,
                source  => [ "puppet:///modules/mysql/vimrc" ],
        }

	file { "/home/sadams/.my.cnf":
                owner => "sadams",
                group => "sadams",
                mode  => 600,
                source  => [ "puppet:///modules/mysql/.my.cnf" ],
        }
}

class mysql::shaunsenv1 inherits mysql::baseshaunsenv {

        file { "/home/sadams/.bashrc":
                owner => "sadams",
                group => "sadams",
                mode  => 644,
		source  => [ "puppet:///modules/mysql/bashrc" ],
        }
}

class mysql::shaunsenv1a inherits mysql::baseshaunsenv {

        file { "/home/sadams/.bashrc":
                owner => "sadams",
                group => "sadams",
                mode  => 644,
                source  => [ "puppet:///modules/mysql/bashrc-multi" ],
        }
}

class mysql::shaunsenv1b inherits mysql::baseshaunsenv {

        file { "/home/sadams/.bashrc":
                owner => "sadams",
                group => "sadams",
                mode  => 644,
                source  => [ "puppet:///modules/mysql/bashrc-multi2" ],
        }
}

class mysql::shaunsenv2 {

        file { "/home/sadams/.bashrc":
                owner => "sadams",
                group => "dbadmins",
                mode  => 644,
                source  => [ "puppet:///modules/mysql/bashrc" ],
        }

        file { "/home/sadams/.vimrc":
                owner => "sadams",
                group => "dbadmins",
                mode  => 644,
                source  => [ "puppet:///modules/mysql/vimrc" ],
        }

	file { "/home/sadams/.my.cnf":
                owner => "sadams",
                group => "dbadmins",
                mode  => 600,
                source  => [ "puppet:///modules/mysql/.my.cnf" ],
        }
}

class mysql::shaunsenv2a {

        file { "/home/sadams/.bashrc":
                owner => "sadams",
                group => "dbadmins",
                mode  => 644,
                source  => [ "puppet:///modules/mysql/bashrc-multi" ],
        }

	file { "/home/sadams/.vimrc":
                owner => "sadams",
                group => "dbadmins",
                mode  => 644,
                source  => [ "puppet:///modules/mysql/vimrc" ],
        }

        file { "/home/sadams/.my.cnf":
                owner => "sadams",
                group => "dbadmins",
                mode  => 600,
                source  => [ "puppet:///modules/mysql/.my.cnf" ],
        }
}
