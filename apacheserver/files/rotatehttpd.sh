#!/bin/bash

####
## Managed by Puppet.  Do not edit.
####
LF='access_log'
YD=`date -dyesterday +%y%m%d`


cd /var/www
for ldir in *
do
        cd /var/www
        cd $ldir/logs/
        echo $ldir
        mv $LF ex$YD.log
        gzip -f ex$YD.log
        mv error_log error_log$YD.log
        gzip -f error_log$YD.log
done

killall -HUP httpd
killall -HUP httpd.worker
