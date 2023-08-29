#!/bin/bash

_sudo=0
_sudonopwd=0

while [ "$#" -gt 0 ]
do
	case "$1" in
		--username) echo "Username set ($2)" >> "/tmp/create-linux-user.log"; _username="$2"; shift;;
		--password) echo "Password set (********)" >> "/tmp/create-linux-user.log"; _password="$2"; shift;;
		--pubkey) echo "Pubkey set ($2)" >> "/tmp/create-linux-user.log"; _pubkey="$2"; shift;;
		--sudoperm) echo "Sudo set ($2)" >> "/tmp/create-linux-user.log"; _sudo=$2; shift;;
		--sudonopwd) echo "SudoNoPwd set ($2)" >> "/tmp/create-linux-user.log"; _sudonopwd=$2; shift;;
		*) echo "finished";;
	esac
	shift
done

echo "Username:         $_username" >> "/tmp/create-linux-user.log"
#echo "Password:         $_password" >> "/tmp/create-linux-user.log"
echo "Pukkey:           $_pubkey" >> "/tmp/create-linux-user.log"
echo "Sudo permissions: $_sudo" >> "/tmp/create-linux-user.log"
echo "Sudo no-passwd:   $_sudonopwd" >> "/tmp/create-linux-user.log"

if [ "$_username" == "" ]; then echo "No user given. Exit." >> "/tmp/create-linux-user.log"; exit 1; fi


_os_name=$(grep NAME /etc/os-release -w |awk -F '=' '{print $2}')
echo "Detected OS: $_os_name" >> "/tmp/create-linux-user.log"

if ( ! getent passwd ${_username} >> /dev/null)
then
  if ( echo $_os_name | grep -iE "CentOS|SLES|Red Hat" >> /dev/null); then
    echo "User doesn't exist. Create user for $_os_name" >> "/tmp/create-linux-user.log"
    useradd --home-dir /home/${_username} --shell /bin/bash --create-home --user-group ${_username} >> /dev/null
  fi
  if (echo $_os_name | grep -i "Ubuntu" >> /dev/null); then
    echo "User doesn't exist. Create user for Ubuntu" >> "/tmp/create-linux-user.log"
    adduser --force-badname --home /home/${_username} --disabled-password --gecos "" --shell /bin/bash ${_username} >> /dev/null
  fi

else
	echo "User exist. Skip" >> "/tmp/create-linux-user.log"
fi

if ( ! getent passwd ${_username} >> /dev/null)
then
	echo "User not found and not created. Exit" >> "/tmp/create-linux-user.log"
	exit 1
fi

if [ ! "$_password" == "" ]
then
	if (getent passwd ${_username} >> /dev/null)
	then
		echo "change password" >> "/tmp/create-linux-user.log"
		echo ${_username}:${_password} | chpasswd
		if [ ! "$?" == "0" ]; then echo "Failed to set password." >> "/tmp/create-linux-user.log"; exit 1; fi
	else
		echo "User not found. Exit." >> "/tmp/create-linux-user.log"
		exit 1
	fi
else
	echo "No password given. Skip" >> "/tmp/create-linux-user.log"
fi

if [ "$_sudo" == "1" ] || [ "$_sudonopwd" == "1" ]
then
    if (echo $_os_name | grep -iE "CentOS|SLES|Red Hat" >> /dev/null)
    then
        echo "Give permissions to user for $_os_name" >> "/tmp/create-linux-user.log"
        usermod -aG root ${_username}
    fi
    if (echo $_os_name | grep -i "Ubuntu" >> /dev/null)
    then
        echo "Give permissions to user for Ubuntu" >> "/tmp/create-linux-user.log"
        usermod -aG sudo ${_username}
    fi
fi

if [ "$_sudonopwd" == "1" ]
then
	echo "Give permissions to user" >> "/tmp/create-linux-user.log"
	echo "${_username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${_username}
fi

_sshdir="/home/${_username}/.ssh"
if [ ${_username} == "root" ]; then _sshdir="/root/.ssh"; fi
echo "ssh dir is set to ""${_sshdir}""" >> "/tmp/create-linux-user.log"
if [ -d ${_sshdir} ]; then echo "Delete existing ssh dir" >> "/tmp/create-linux-user.log"; rm -rf ${_sshdir}; fi
echo "Create new ssh dir" >> "/tmp/create-linux-user.log"
mkdir ${_sshdir}
echo "Set permissions for newly created directory" >> "/tmp/create-linux-user.log"
chown ${_username}:${_username} ${_sshdir}
chmod 700 ${_sshdir}

if [ "$_pubkey" == "" ]
then
	echo "Create new ssh authorized_keys files with no keys" >> "/tmp/create-linux-user.log"
	touch ${_sshdir}/authorized_keys
else
	echo "Create new ssh authorized_keys files with given keys" >> "/tmp/create-linux-user.log"
	echo ${_pubkey} >> ${_sshdir}/authorized_keys
fi
chown ${_username}:${_username} ${_sshdir}/authorized_keys
echo "Set permissions on keys file" >> "/tmp/create-linux-user.log"
chmod 600 ${_sshdir}/authorized_keys