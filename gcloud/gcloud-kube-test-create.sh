#!/usr/bin/env bash

GCLOUD_PRJ=kube-test-260704
CLUSTER_NAME=kube-test
KEY_FILE=~/.config/gcloud/key.json

if [ ! -f "$KEY_FILE" ]; then
  echo "${KEY_FILE} does not exist"
  exit 1
fi

gcloud auth activate-service-account 252117346574-compute@developer.gserviceaccount.com --key-file ${KEY_FILE} --project=${GCLOUD_PRJ}
gcloud config set compute/zone asia-southeast1-a
gcloud config set project ${GCLOUD_PRJ}
gcloud config set container/use_client_certificate false
gcloud container clusters create ${CLUSTER_NAME} --num-nodes=2 --machine-type=n1-standard-1 --zone=asia-southeast1-a
# gcloud container clusters update ${CLUSTER_NAME} --update-addons=NetworkPolicy=ENABLED
# gcloud container clusters update ${CLUSTER_NAME} --enable-network-policy
gcloud container clusters get-credentials ${CLUSTER_NAME}
