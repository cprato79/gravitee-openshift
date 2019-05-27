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

#delete objects
oc delete dc mongodb -n $PRJ_NAME
oc delete services mongodb -n $PRJ_NAME
oc delete imagestream mongodb -n $PRJ_NAME

oc delete dc elasticsearch -n $PRJ_NAME
oc delete services elasticsearch -n $PRJ_NAME
oc delete imagestream elasticsearch -n $PRJ_NAME

oc delete dc managementui -n $PRJ_NAME
oc delete services managementui -n $PRJ_NAME
oc delete route managementui -n $PRJ_NAME
oc delete imagestream management-ui -n $PRJ_NAME
oc delete bc management-ui -n $PRJ_NAME

oc delete dc managementapi -n $PRJ_NAME
oc delete services managementapi -n $PRJ_NAME
oc delete route managementapi -n $PRJ_NAME
oc delete imagestream management-api -n $PRJ_NAME
oc delete bc management-api -n $PRJ_NAME

oc delete dc gateway -n $PRJ_NAME
oc delete services gateway -n $PRJ_NAME
oc delete route gateway -n $PRJ_NAME
oc delete imagestream gateway -n $PRJ_NAME
oc delete bc gateway -n $PRJ_NAME

oc delete persistentvolumeclaim elasticdata -n $PRJ_NAME
oc delete persistentvolumeclaim mongodata -n $PRJ_NAME
