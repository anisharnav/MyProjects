#!/bin/bash
#
<< Info

create daily backups and rotation upto 5 days.

Usage: ./backup.sh <path to your source> <path to your backups>
Info


function display_usage () {

		echo "Usage: ./backup.sh <path to your source> <path to your backups>"
	}

	if [ $# -ne  2 ]; then
		display_usage
	fi


source_dir=$1
backup_dir=$2
time_stamp=$(date '+%Y-%m-%d-%H-%M-%S')

function create_backup () {
	
	zip -r "${backup_dir}/backup_${time_stamp}.zip" "${source_dir}" > /dev/null


	if [ $? -eq 0 ]; then

	echo "backup generated successfully for ${time_stamp}"

	fi
}


function perform_rotation () {

	backups=($(ls -t "${backup_dir}/backup_"*.zip))

	if [ ${#backups[@]} -gt 5 ]; then
	echo "Permorming rotation for 5 days"
	
	backups_to_remove=("${backups[@]:5}")

	for backup in "${backups_to_remove[@]}"

	do 
                rm -f ${backup}
	done
	fi	

}

create_backup
perform_rotation
