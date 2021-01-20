#!/bin/bash
########################################### ABOUT ##############################################
#
# Name: computer_group_update_macos.sh
# Date: Jan 2021
# By: Niklas Blomdalen
# Based on the work by Steven Russell
#
########################################## VARIABLES ############################################
### Change the values here:

### API Info
api_user="api_user_here"
api_pass="api_pass_here"

## JAMF URL
jss_url="https://jss.domain:8443"

# API Permissions, ensure that the api_user is configured under "Jamf Pro Server Actions" to have the "Send Computer Remote Command to Download and Install macOS Update"

## Static or Smart Group ID here
# Insert the groupID here, found easily in the URL of the mobile device smart group
# Using a smart computer group called Supervised devices, with one criteria: should be Supervised is Yes
# For example: https://jss.domain:8443/smartComputerGroups.html?id=xxx&o=r
#____________________________________________Smart_Group_ID_Here___^^^____

group_id="000"


############################################# MAIN ##############################################
# Do not edit the line below
IFS=' '
# We are going to grab the computer device IDs first from the smart or static group and place them into an array to loop through.

/bin/echo "Gather computer device IDs from group: $group_id"
members_of_group=$(/usr/bin/curl -sku "${api_user}:${api_pass}" ${jss_url}/JSSResource/computergroups/id/${group_id} | xpath //computer_group/computers/computer/id | tr '</id>' '\n')
array_id=$(/bin/echo $members_of_group | awk '$1=$1' | tr '\n' ' ')

#count items in array
array_calc=$(echo ${array_id} | wc -w)
array_size=$(echo $array_calc | sed -e 's,\\[trn],,g')
count=1

# for loop through each computer device id and apply the actions
for device_id in $array_id; do
    #### Going to output some sort of progress to the screen...
    /bin/echo "Computer number: $count of $array_size"
    ((count=count+1))
    
    #### SEND DOWNLOAD OS UPDATES COMMAND: (pick one or the other here, depending on how forceful you want to be)
    /usr/bin/curl -sku "${api_user}:${api_pass}" ${jss_url}/JSSResource/computercommands/command/ScheduleOSUpdate/id/"${device_id}" -X POST > /dev/null
    
    #### SEND INSTALL OS UPDATES COMMAND: (this is more forceful)
    #/usr/bin/curl -sku "${api_user}:${api_pass}" ${jss_url}/JSSResource/computercommands/command/ScheduleOSUpdate/action/install/id/"${device_id}" -X POST > /dev/null
    if [ $? = 0 ]; then
        /bin/echo "Computer ID: ${device_id} successfully sent update command"
    else
        /bin/echo "Computer ID: ${device_id} failed to send update command"
    fi
    sleep 1
done
