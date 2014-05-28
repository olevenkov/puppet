#!/bin/bash

####
## Managed by Puppet.  Do not edit.
####
JN='mts-nature mts-ncb mts-nm mts-nbt mts-ng mts-nsmb mts-np mts-nclim'
LF='access.log'
YD=`date -dyesterday +%y%m%d`


cd /var/www
for ldir in *
do
        cd /var/www
        cd $ldir/logs/
        echo $ldir
        for journal in $JN
        do
                mv $journal-$LF $journal-ex$YD.log
                gzip -f $journal-ex$YD.log
                mv $journal-error.log $journal-error-$YD.log
                gzip -f $journal-error-$YD.log
        done
done

killall -HUP httpd
killall -HUP httpd.worker
