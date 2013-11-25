#!/bin/bash

# sudo ./install-ss.sh

DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
echo $DISTRO


if [ $DISTRO == 'Debian' ]; then
    apt-get install build-essential autoconf libtool libssl-dev gcc
#elif [ $DISTRO == 'Ubuntu' ]; then
elif [ $DISTRO == 'CentOS' ]; then
    yum install build-essential autoconf libtool openssl-devel gcc
else
    echo unknown;exit;
fi

#type ss-server > /dev/null 2>&1 && echo 1
if type ss-server > /dev/null 2>&1; then
    echo ss-server has been installed.;
else
    #http://goo.gl/DNI7E
    #https://api.github.com/repos/madeye/shadowsocks-libev/zipball/
    #python:http://goo.gl/pYcWQc, nodejs:http://goo.gl/7bG1OT
    if [ ! -f shadowsocks-libev.zip ]; then
        wget -O shadowsocks-libev.zip http://git.io/OygkRA
        unzip -q shadowsocks-libev.zip
    fi
    cd madeye-shadowsocks-libev*
    ./configure && make
    make install
fi

read -p "* Setup and configuration. Continue (y/n)? "
[ "$REPLY" == "y" ] || exit 0

defPwd='2013'
defPort='9527'

read -p "* Enter ss-server password (default: $defPwd): " pwd 
pwd=${pwd:-$defPwd}

read -p "* Enter ss-server port (default: $defPort): " port
port=${port:-$defPort}

echo 'start server...'
# ss-server -s [server ip] -p [server port] -k [password] -m [encrypt_method]
#echo ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid
#nohup ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid
nohup ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid > nohup.out 2>&1

if [ $(ps aux | grep ss-server | grep -v "grep" | wc -l) -eq 1 ]; then
echo 'succeeded !'
else
echo 'failed !'
fi

echo 
echo '---------'
echo "open port: iptables -A INPUT -p tcp -m tcp --dport $port -j ACCEPT"

echo 'run on startup:'
if [ $DISTRO == 'Debian' ]; then
    echo "\"nohup ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid\" >> /etc/init.d/rc.local"
elif [ $DISTRO == 'CentOS' ]; then
    echo "\"nohup ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid\" >> /etc/rc.local"
fi

echo 'kill ss-server: kill `cat /var/run/ss.pid`'
echo 'print processes: ps aux|grep ss-server'

