#!/usr/bin/env bash
hostname=$(hostname)
date=$(date +"%Y-%m-%d")
backupDir="/backups"

while getopts u:h: flag
do
    case "${flag}" in
        u) backupServerUser=${OPTARG};;
        h) backupServerHost=${OPTARG};;
    eac
done
backupServerUser="caleb"
backupServerHost="192.168.0.122"

cd /
echo $(pwd)
# Create backup dir if it does not exist
function backup ()
{
    if [ -d "$backupDir" ]; then
        sudo tar -czvf "${backupDir}/${hostname}_${date}.tar.gz" "home/$(whoami)"
        echo "Ran backup"
    else
        mkdir ${backupDir}
        # Recursively call to create dir
        echo "Backup dir created"
        backup
    fi
}

# Delete backups older than one month
function deleteOldBackups()
{
    files=(${backupDir}/*)
    for fileName in ${files[@]}; do
        # IFS='_' read -ra DATE <<< "$fileName"
        
        # Check if date is older than one month
        if [[ $fileName =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
            echo "date regex: ${BASH_REMATCH[0]}"
            if [ ! -z ${BASH_REMATCH[0]} ]; then
                fileDate=$(date -d "${BASH_REMATCH[0]}")
                cutoffDate=$(date -d "-1 month")

                if [[ "$fileDate" > "$cutoffDate" ]]; then
                    continue
                else
                    rm $fileName
                    echo "Deleted ${fileName}"
                    continue
                fi
            else
                echo "Date is invalid"
                continue
            fi
            echo "Filename is invalid"
            continue
        fi 
    done
}

function syncToRemote()
{
    rsync -a $backupDir $backupServerUser@$backupServerHost:$backupDir
}

function main()
{
    deleteOldBackups
    backup
}
main
