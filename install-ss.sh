#!/bin/bash

# wget -qO- http://git.io/ITgkvw | sudo sh
# or: su -c "wget -qO- http://git.io/ITgkvw | sh"

if [[ -f /usr/bin/lsb_release ]]; then
    DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
elif [ -f "/etc/redhat-release" ]; then
    DISTRO=$(egrep -o 'Fedora|CentOS|Red.Hat' /etc/redhat-release)
elif [ -f "/etc/debian_version" ]; then
    DISTRO=='Debian'
fi
echo $DISTRO

export PATH=/usr/local/bin/:$PATH #for CentOS sudo which

if [ $DISTRO == 'Debian' ]; then
    apt-get install build-essential autoconf libtool libssl-dev gcc
#elif [ $DISTRO == 'Ubuntu' ]; then
elif [ $DISTRO == 'CentOS' ]; then
    yum install build-essential autoconf libtool gcc openssl openssl-devel make
else
    echo unknown;exit;
fi

#type ss-server > /dev/null 2>&1 && echo 1
if which ss-server > /dev/null 2>&1; then # sudo: type: command not found
    echo '* ss-server has been installed.'
else
    # http://goo.gl/DNI7E
    # https://api.github.com/repos/madeye/shadowsocks-libev/zipball/
    # python:http://goo.gl/pYcWQc, nodejs:http://goo.gl/7bG1OT
    ss=shadowsocks-libev
    if [ ! -f $ss.zip ]; then
        wget -O $ss.zip http://git.io/OygkRA
        unzip -q $ss.zip
    fi
    cd *-$ss*
    ./configure && make
    make install
fi

# Check if sudo
if [ "$(whoami)" == "root" ]; then
    sudo -k # sudo: read: command not found
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
running=$(ps aux | grep ss-server | grep -v "grep" | wc -l)

if [ ! $running -eq 1 ]; then
    # ss-server -s [server ip] -p [server port] -k [password] -m [encrypt_method]
    # echo ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid
    nohup ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid > nohup.out 2>&1
    if [ $running -eq 1 ]; then
        echo 'succeeded !'
    else
        echo 'failed !'
    fi
else
    echo '* ss-server has been running'
fi

echo 
echo '---------'
echo "open port: iptables -A INPUT -p tcp -m tcp --dport $port -j ACCEPT"

echo 'run on startup:'
startup_cmd='"nohup ss-server -s 0.0.0.0 -p $port -k $pwd -m aes-256-cfb -t 60 -f /var/run/ss.pid"'
if [ $DISTRO == 'Debian' ]; then
    echo "$startup_cmd >> /etc/init.d/rc.local"
elif [ $DISTRO == 'CentOS' ]; then
    echo "$startup_cmd >> /etc/rc.local"
fi

echo '* print processes: ps aux|grep ss-server'
echo '* kill ss-server: kill `cat /var/run/ss.pid`'

