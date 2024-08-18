#!/bin/bash

alert=30

df -H | awk '{print $1 " " $5}' | while read output;

do
        usage=$(echo $output | awk '{print $2}' | cut -d'%' -f1)

        file_system=$(echo $output | awk '{print $1}')

        if [ $usage -ge $alert ]
        then
                echo "CRITICAL for $file_system"
        fi
done
