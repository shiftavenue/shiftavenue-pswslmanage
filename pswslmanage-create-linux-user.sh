#!/bin/bash

if [ -z ${_step_counter+x} ]; then _step_counter=0; fi
step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;31m%d) %s\033[0m\n' $_step_counter "Manage-Users: $@" >&2  # bold cyan
}
_sudo=0
_sudonopwd=0

while [ "$#" -gt 0 ]
do
	case "$1" in
		--username) printf "Username set ($2)\n"; _username="$2"; shift;;
		--password) printf "Password set (********)\n"; _password="$2"; shift;;
		--pubkey) printf "Pubkey set (********)\n"; _pubkey="$2"; shift;;
		--sudoperm) printf "Sudo set ($2)\n"; _sudo=1; shift;;
		--sudonopwd) printf "SudoNoPwd set ($2)\n"; _sudonopwd=1; shift;;
		*) echo "finished";;
	esac
	shift
done

printf "Username:         $_username \n"
#printf "Password:         $_password \n"
#printf "Pukkey:           $_pubkey \n"
printf "Sudo permissions: $_sudo \n"
printf "Sudo no-passwd:   $_sudonopwd \n"

if [ "$_username" == "" ]; then printf "No user given. Exit."; exit 1; fi


_os_name=$(grep NAME /etc/os-release -w |awk -F '=' '{print $2}')
printf "Detected OS: $_os_name"

step 'Check user and create if needed'
if ( ! getent passwd ${_username} >> /dev/null)
then
  if ( echo $_os_name | grep -iE "CentOS|SLES|Red Hat" >> /dev/null); then
    printf "User doesn't exist. Create user for $_os_name\n"
    useradd --home-dir /home/${_username} --shell /bin/bash --create-home --user-group ${_username}
  fi
  if (echo $_os_name | grep -i "Ubuntu" >> /dev/null); then
    printf "User doesn't exist. Create user for Ubuntu\n"
    adduser --force-badname --home /home/${_username} --disabled-password --gecos "" --shell /bin/bash ${_username}
  fi

else
	printf "User exist. Skip\n"
fi

if ( ! getent passwd ${_username} >> /dev/null)
then
	printf "User not found and not created. Exit\n"
	exit 1
fi

step 'Set password'
if [ ! "$_password" == "" ]
then
	if (getent passwd ${_username} >> /dev/null)
	then
		printf "change password\n"
		echo ${_username}:${_password} | chpasswd
		if [ ! "$?" == "0" ]; then echo "Failed to set password."; exit 1; fi
	else
		printf "User not found. Exit.\n"
		exit 1
	fi
else
	printf "No password given. Skip\n"
fi

step 'Sudo permissions'
if [ "$_sudo" == "1" ] || [ "$_sudonopwd" == "1" ]
then
    if (echo $_os_name | grep -iE "CentOS|SLES|Red Hat" >> /dev/null)
    then
        echo "Give permissions to user for $_os_name"
        usermod -aG root ${_username}
    fi
    if (echo $_os_name | grep -i "Ubuntu" >> /dev/null)
    then
        echo "Give permissions to user for Ubuntu"
        usermod -aG sudo ${_username}
    fi
fi

step 'Sudo-NoPwd permissions'
if [ "$_sudonopwd" == "1" ]
then
	echo "Give permissions to user"
	echo "${_username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${_username}
fi

step 'create ssh directory for user with public key'
_sshdir="/home/${_username}/.ssh"
if [ ${_username} == "root" ]; then _sshdir="/root/.ssh"; fi
printf "ssh dir is set to ""${_sshdir}""\n"
if [ -d ${_sshdir} ]; then printf "Delete existing ssh dir\n"; rm -rf ${_sshdir}; fi
printf "Create new ssh dir\n"
mkdir ${_sshdir}
printf "Set permissions for newly created directory\n"
chown ${_username}:${_username} ${_sshdir}
chmod 700 ${_sshdir}

if [ "$_pubkey" == "" ]
then
	printf "Create new ssh authorized_keys files with no keys\n"
	touch ${_sshdir}/authorized_keys
else
	printf "Create new ssh authorized_keys files with given keys\n"
	echo ${_pubkey} >> ${_sshdir}/authorized_keys
fi
chown ${_username}:${_username} ${_sshdir}/authorized_keys
printf "Set permissions on keys file\n"
chmod 600 ${_sshdir}/authorized_keys