#!/bin/bash
###########################################################################
# File Name: mk_sudoer.sh
# Author: yushuibo
# Mail: hengchen2005@gmail.com
# Descraption: 通过一个hosts映射文件来批量把账号添加到sudoers里面，且sudo时免密码。
# Created Time: 2017-11-07 19:11:02
###########################################################################

MASTER_IP='10.0.1.46'

[ $# -ne 1 ] && {
	echo "UASGE: `basename $0` host_file"
	exit 10
}

file=$1
[ -f $file ] || {
	echo "$file not found."
	exit 11
}
hosts=(`cat $file|grep -Ev "^#"|awk -F ':' '{print $2}'`)
auth='kgF^91@bhL_2018=JMgame%'

[ $UID -ne 0 ] && {
    echo "Only the root user can be execute this scripts!"
    exit 100
}

[ `rpm -qa expect|wc -l` -eq 0 ] && yum install -y expect
 
chsalt_id(){
    local host=$1
    /usr/bin/expect <<EOF
set timeout -1
spawn ssh root@$host
expect {
    "yes/no" { send "yes\r";exp_continue; }
    "*password" { send "$auth\r";exp_continue; }
	"root@" { 
		send { yum install -y salt-minion }
		send "\r"
		send { sed -i "s/#master: salt/master: $MASTER_IP/g" /etc/salt/minion }
		send "\r"
		send { sed -i "s/#id:/id: \`hostname\`/g" /etc/salt/minion }
		send "\r"
		send { /etc/init.d/salt-minion start }
		send "\r"
		send "exit 1\r"
		expect eof
		exit
	 } 
}
EOF
}

for host in ${hosts[*]};do
    chsalt_id $host
done
