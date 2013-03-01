#! /usr/bin/env bash

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../install-common.sh

myT1 "Init MySQL DB"

initDb
