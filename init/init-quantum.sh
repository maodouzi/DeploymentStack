#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT2 "Init Quantum!"

myT3 "Run Quantum"
stopQuantum
startQuantum

myT3 "Check Quantum Type"

myT2 "End Init Quantum!"

