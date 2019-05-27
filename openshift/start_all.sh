#!/bin/bash

# getting user inputs
while [[ $PRJ_NAME == '' ]]
do
    read -p "Enter the Project Name [gravitee]: " PRJ_NAME
    PRJ_NAME="$(echo $PRJ_NAME | tr '[:upper:]' '[:lower:]')"
    [ -z "$PRJ_NAME" ] && PRJ_NAME="gravitee"
    echo "The Project Name is: $PRJ_NAME"
done
echo -e " "

oc login -u developer -p developer
oc project $PRJ_NAME

# Start all
oc scale dc/elasticsearch --replicas=1
oc scale dc/mongodb --replicas=1
oc scale dc/gateway --replicas=1
oc scale dc/managementui --replicas=1
oc scale dc/managementapi --replicas=1
