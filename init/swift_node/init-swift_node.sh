#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Swift Node!"

myT3 "Run Swift Node"
stopSwift
startSwiftNode

myT2 "End Swift Node!"
