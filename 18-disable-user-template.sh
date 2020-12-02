#!/bin/bash
#===============================================================================
#
#          FILE: 18-disable-user.sh
# 
#         USAGE: ${0} [-d] [-r] [-a] USER ...
# 
#   DESCRIPTION: This script disables, deletes, and/or archives users on the 
#				 local system.
#        AUTHOR: Manel  Ferrer
#  ORGANIZATION: INS Pedralbes
#       CREATED: 23/11/2020 08:53:24 AM
#      REVISION:  ---
#	Video: https://asciinema.org/a/PkjVDWjR12OMZMgDwUYbyzuNf
#===============================================================================

#Display the usage and exit
usage() {
  echo "Usage: ${0} [-d] [-r] [-a] USER ..." >&2
  echo 'Disable/delete/backup a local Linux account.' >&2
  echo '  -d  Disable account' >&2
  echo '  -r  Remove the account' >&2
  echo '  -a  Creates an archive of the home directory associated with the account(s).' >&2
  exit 1
}

# Proper user?: not exists or account id is at least 1000.
checkUser(){
	UserID=$(id -u $1)
	if [ $? -ne 0  ]
	then exit 1
	else
		if [ $UserID -le 1000 ]
		then
			echo "Refusing to remove the mail account with UID $UserID under 1000"
			echo "No es posible"
			exit 1
		fi 
	fi
}

# This function sends a message to syslog and to standard output if VERBOSE is true.
log() {
  local MESSAGE="${@}"
  if [[ "${VERBOSE}" = 'true' ]]
  then
    echo "${MESSAGE}"
  fi
  logger -t luser-demo10.sh "${MESSAGE}" #pots veure missatge: tail -1 /var/log/syslog
}

# This function creates a backup of a directory.  Returns non-zero status on error.
backup_dir() {
  echo "Comenca backup de ${1}"
  local DIR="/home/$1"
  # Make sure the file exists.
  if [[ -d "${DIR}" ]]
   then
    echo "Es un directori"
    local BACKUP_FILE="/archives/$(basename ${1}).$(date +%F-%N)"
    log "Backing up $1 to ${BACKUP_FILE}."
	if [ ! -d "/archives" ]; then
		`mkdir /archives`
    fi
    # The exit status of the function will be the exit status of the cp command.
    tar -cvf $BACKUP_FILE.tar ${DIR}
  else
    # The file does not exist, so return a non-zero exit status.
    echo NO existeix
    return 1
  fi
}

# Run as root.
if [ $EUID -ne 0  ]
then echo "Please run as root"
exit 1
fi
#Parse the options
while getopts ":d:r:a:" o; do
    # OPTIND és variable interna de  getops, índex 
    #echo "OPTIND: $OPTIND OPTARG: $OPTARG"
    case "${o}" in
	# OPTARG és una variable pròpia de getops i va canviant a cada 
	# iteració: representa el valor l'opció que està tractant
        d)
              USERdisable=$OPTARG
              # Make sure the UID of the account is at least 1000.
		checkUser $USERdisable
	      #deshabilitat usuari
	      usermod -L $USERdisable
	      #comprova usuari deshabilitat
	      if [ $? -ne 0  ]
		then echo "Algo ha salido mal y no se ha podido deshabilitar"
		else echo "$USERdisable ha sido deshabilitado"	
	      fi
			  
            ;;
        r)
            USERremove=$OPTARG
            # Make sure the UID of the account is at least 1000.
		checkUser $USERremove
			# elimina usuari
		userdel -r $USERremove > /dev/null 2>&1
			# Check user is deleted.
		if [ $? -ne 0  ]
                 then echo "Algo ha salido mal y no se ha podido eliminar"
                 else echo "$USERremove ha sido eliminado"  
               fi
            ;;
	     a)
	        USERbackup=$OPTARG
	        # Make sure the UID of the account is at least 1000.
		checkUser $USERbackup 
	        #crida a la funcio que fa el backup de la home de lusuari
		backup_dir $USERbackup
            ;;
	#entra aquí quan s'introdueix opció però no pas argument, sent aquest
	#obligatori
        :)
            echo "ERROR: Option -$OPTARG requires an argument"
            usage
            ;;
	#entra aqui quan l'opció no és vàlida
        \?)
            echo "ERROR: Invalid option -$OPTARG"
            usage
            ;;
    esac
done
# Quan es crida l'script sense cap opció o parametre
#-z string True if the string is null (an empty string)
if [ -z $USERdisable ] && [ -z $USERremove ] && [ -z $USERbackup ]; then
    echo "Sense cap opció o paràmetre"
    usage
fi


