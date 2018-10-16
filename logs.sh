#!/bin/bash
# Program for Log Collection
# 10-16-18

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--date)
    DATE="$2"
    shift
    shift
    ;;
    -s|--startdate)
    SDATE="$2"
    shift
    shift
    ;;
    -f|--fenrirpath)
    FPATH="$2"
    shift
    shift
    ;;
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done

set -- "${POSITIONAL[@]}"

if [ ! -d logs ]; then
    mkdir logs
fi
cd logs

#logs

echo 'Collecting logs...'
ls /var/log > log_names
if [ -z ${SDATE+x} ]; then
    cat /var/log/auth.log | grep -i "$DATE" > auth.log
    cat /var/log/kern.log | grep -i "$DATE" > kern.log
else
    sed -n '/'"$SDATE"'/, $p' /var/log/auth.log > auth.log
    sed -n '/'"$SDATE"'/, $p' /var/log/kern.log > kern.log
fi
cat /var/log/syslog | grep -i "$DATE" > syslog
echo 'Done'

#system info

echo 'Collecting system info...'
systemctl list-sockets > sysctl_sockets
systemctl list-timers --all > sysctl_timers
systemctl list-units > sysctl_units
echo 'Done'

#executables

echo 'Searching executables...'
{
sudo find / -user root -perm -4000 -print > root_permissions
sudo find / -group kmem -perm -2000 -print > group_permissions
} &> error.log
echo 'Done'

#user info

echo 'Collecting user info...'
getent passwd > passwd
getent group > group
echo 'Done'

#hidden files

echo 'Searching for hidden files...'
{
sudo find / -name '.*' -print > hidden_files 
}&>> error.log
echo 'Done'

#network info

echo 'Collecting network info...'
sudo iptables -t nat -vnL > port_forwarding
sudo netstat -tupn > connections
cat /etc/hosts > hosts
echo "Allow" >> hosts
cat /etc/hosts.allow >> hosts
echo 'Done'

#cron jobs

echo 'Collecting cron info...'
ls /etc/cron* > crons
echo 'Done'

#Adding Fenrir

cd ..
if [ ! -d Fenrir ]; then
    echo 'Adding Fenrir...'
    git clone https://github.com/Neo23x0/Fenrir
    cd Fenrir/
    rm -rf ansible/
    rm -rf demo/
    rm -rf screens/
    cd ..
    echo 'Done'
fi

#Running fenrir

echo 'Running Fenrir...'
cd Fenrir/
if [ -f FENRIR_* ]; then
    rm FENRIR_*
fi

if [ -z $FPATH ]
    then ./fenrir.sh /
    else ./fenrir.sh $FPATH
fi
cat FENRIR_* > ./../logs/fenrir
rm FENRIR_*
echo 'Done'
echo 'Buy-Buy'
