#! /usr/bin/env bash 

TOP_DIR=$(cd $(dirname "$0") && pwd)
source ${TOP_DIR}/../../install-common.sh

myT2 "Init Swift Proxy!"

myT3 "Run Swift Proxy"
stopSwift
startSwiftProxy

myT2 "End Init Swift Proxy!"

