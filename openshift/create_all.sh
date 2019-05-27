#!/bin/bash
###################################################################
#Script Name                : create_all.sh
#Description                : it creates all openshift objects
#Args                       :
#Author                     : Claudio Prato
#Email                      : cprato79@gmail.com
###################################################################

# getting user inputs
while [[ $PRJ_NAME == '' ]]
do
    read -p "Enter the Project Name [gravitee]: " PRJ_NAME
    PRJ_NAME="$(echo $PRJ_NAME | tr '[:upper:]' '[:lower:]')"
    [ -z "$PRJ_NAME" ] && PRJ_NAME="gravitee"
    echo "The Project Name is: $PRJ_NAME"
done
echo -e " "
while [[ $OPENSHIFT_USERADMIN == '' ]]
do
    read -p "Enter the Openshift SystemAdmin user [system:admin]: " OPENSHIFT_USERADMIN
    OPENSHIFT_USERADMIN="$(echo $OPENSHIFT_USERADMIN | tr '[:upper:]' '[:lower:]')"
    [ -z "$OPENSHIFT_USERADMIN" ] && OPENSHIFT_USERADMIN="system:admin"
    echo "The Openshift SystemAdmin user is: $OPENSHIFT_USERADMIN"
done
echo -e " "
while [[ $OPENSHIFT_SUFFIXE == '' ]]
do
    read -p "Enter the Host resolution address for openshift cluster [10.5.18.122.nip.io]: " OPENSHIFT_SUFFIXE
    [ -z "$OPENSHIFT_SUFFIXE" ] && OPENSHIFT_SUFFIXE="10.5.18.122.nip.io"
    echo "The Openshift host resolution address is: $OPENSHIFT_SUFFIXE"
done
echo -e " "

read -p "Optional - Enable a secret creation for private git access [on/OFF]: " GIT_SECRET_OPT
GIT_SECRET_OPT="$(echo $GIT_SECRET_OPT | tr '[:upper:]' '[:lower:]')"
[[ -z "$GIT_SECRET_OPT" || "$GIT_SECRET_OPT" != "on" ]] && GIT_SECRET_OPT="off"
echo "The secret's name is: $GIT_SECRET_OPT"
echo -e " "

read -p "Gravitee Version [1.26.0]: " GRAVITEEIO_VERSION
[[ -z "$GRAVITEEIO_VERSION" ]] && export GRAVITEEIO_VERSION="1.26.0"
echo "The gravitee version is: $GRAVITEEIO_VERSION"
echo -e " "

# create pv
echo "persistent volume creation is running."
persistentvolumes/create_pv.sh

# create project
echo "$PRJ_NAME project is creating."
oc login -u developer -p developer
oc new-project $PRJ_NAME

# add service account for host path
oc create serviceaccount $PRJ_NAME -n $PRJ_NAME

# affect policy
oc login -u $OPENSHIFT_USERADMIN
oc project $PRJ_NAME
# set the service account name equal to project name for convenience
SRV_ACC_NAME=$PRJ_NAME
oc adm policy add-scc-to-user anyuid -z $SRV_ACC_NAME

oc login -u developer -p developer

# 1. define an optional secret for git private repo access
# 2. define the builds
# 3. start building
# 4. tag this :latest version to real version being created

# get images
#oc import-image nginx:1.10.2-alpine --confirm
#oc import-image $PRJ_NAMEio/java:8 --confirm

#export GRAVITEEIO_VERSION=1.26.0

add_secret_opt () {
  GIT_SECRET_NAME="gravitee-gitsecret"
  GIT_SECRET_OPT="--source-secret=$GIT_SECRET_NAME"

  # create secret to gravitee project
  oc create -f secret/create_secret.yml -n $PRJ_NAME
  # link secret to build service
  for i in default deployer builder $SRV_ACC_NAME; do oc secret link $i $GIT_SECRET_NAME --for=pull -n $PRJ_NAME;done
}

# ::: set a secret for git private repository to inject to
[[ "$GIT_SECRET_OPT" == "on" ]] && add_secret_opt || GIT_SECRET_OPT=""

# gateway
oc new-build ../ --name=gateway --context-dir=images/gateway/ --strategy=docker $GIT_SECRET_OPT --build-arg=GRAVITEEIO_VERSION=$GRAVITEEIO_VERSION
oc start-build gateway --wait --build-arg=GRAVITEEIO_VERSION=$GRAVITEEIO_VERSION
sleep 5
oc tag gateway:latest gateway:$GRAVITEEIO_VERSION


# management-api
oc new-build ../ --name=management-api --context-dir=images/management-api/ --strategy=docker $GIT_SECRET_OPT --build-arg=GRAVITEEIO_VERSION=$GRAVITEEIO_VERSION
oc start-build management-api --wait --build-arg=GRAVITEEIO_VERSION=$GRAVITEEIO_VERSION
sleep 5
oc tag management-api:latest management-api:$GRAVITEEIO_VERSION

# management-ui
oc new-build ../ --name=management-ui --context-dir=images/management-ui/ --strategy=docker $GIT_SECRET_OPT --build-arg=GRAVITEEIO_VERSION=$GRAVITEEIO_VERSION
oc start-build management-ui --wait --build-arg=GRAVITEEIO_VERSION=$GRAVITEEIO_VERSION
sleep 5
oc tag management-ui:latest management-ui:$GRAVITEEIO_VERSION

# import OpenShift Template
oc process -f ./template-graviteeapim.yaml NAMESPACE=$PRJ_NAME GRAVITEE_VERSION=$GRAVITEEIO_VERSION OPENSHIFT_SUFFIXE=$OPENSHIFT_SUFFIXE | oc create -f -
