#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Horizon!"

myT3 "Run Horizon"
stopHorizon
startHorizon

myT2 "End Init Horizon!"

