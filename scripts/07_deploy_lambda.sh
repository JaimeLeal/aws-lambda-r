#!/bin/bash

# deploy lambda function to Creates an Amazon EC2 virtual machine (an instance)


# load local settings if not already loaded 
[[ $SCR_DIR ]] || SCR_DIR="$(cd "$(dirname "$0")/."; pwd)"
[[ $PRJ_DIR ]] || source "$SCR_DIR/02_setup.sh"


echo -e "$INFO Configure EC2, create lambda package and API method. Please wait ..."

# run the needed scripts when connecting to instance
cat $EC2_SET_1 $EC2_SET_2 $EC2_SET_3 $EC2_SCR_12 $EC2_SCR_13 $EC2_SCR_14 | \
    ssh -i "$EC2_KEY_FILE" \
        -T "${EC2_USERNAME}@${EC2_DNS_NAME}" \
        'bash -s'

exit_status=$?
if [[ $exit_status -eq 0 ]]; then
    echo -e "$INFO Finished creating lambda function and API method."
else
    echo -e "$ERROR Cannot create lambda function / API method."
    source "$SCR_DIR/08_terminate_ec2.sh"
    exit 1
fi