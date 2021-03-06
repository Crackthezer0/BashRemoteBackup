#!/usr/bin/env bash
hostname=$(hostname)
date=$(date +"%Y-%m-%d")
backupDir="/backups"

while getopts u:h: flag
do
    case "${flag}" in
        u) backupServerUser=${OPTARG};;
        h) backupServerHost=${OPTARG};;
    esac
done
backupServerUser="caleb"
backupServerHost="collective-unconscious"

# Create backup dir if it does not exist
function backup ()
{
    if [ -d "$backupDir" ]; then
        rm tar.errors
        tar -czvf "${backupDir}/${hostname}_${date}.tar.gz" -C "/home" "$(whoami)" 2> tar.errors
        backupFail=$(wc -l <tar.errors)
        if [ $(($backupFail)) != 0 ]; then
            echo $backupFail
            echo "Archive creation failed"
            exit
        fi
    else
        dirFail="$(mkdir ${backupDir} 2>&1 > /dev/null)"
        echo $dirFail
        if [ ! -z dirFail ]; then
            echo "Directory creation failed"
            exit
        fi
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
        
        # Check if date is older than one month
        if [[ $fileName =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
            echo "date regex: ${BASH_REMATCH[0]}"
            if [ ! -z ${BASH_REMATCH[0]} ]; then
                fileDate=$(date -d "${BASH_REMATCH[0]}")
                cutoffDate=$(date -d "-1 month")

                if [[ $fileDate < $cutoffDate ]]; then
                    echo "skipped"
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
    rsync -a --progress $backupDir/* "$backupServerUser"@"$backupServerHost:/backups" > $backupDir/rsync.progress
}

function main()
{
    deleteOldBackups
    backup
    syncToRemote
}
main
