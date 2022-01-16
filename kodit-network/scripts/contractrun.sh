#!/bin/bash

CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel"}


echo "---------- Insert chaincode 1 -------------- "
set -x
peer chaincode invoke -o orderer.intellicode.com:7050 -C $CHANNEL_NAME -n mychaincode -c '{"Args":["insert", "157", "1234567890ABCDEF1234567890ABCDEF"]}' >& log.txt
set +x
cat log.txt
echo "Key: 157"
echo "Hash: 1234567890ABCDEF1234567890ABCDEF" 
echo

sleep 3

echo "---------- Insert chaincode 2  -------------- "
set -x
peer chaincode invoke -o orderer.intellicode.com:7050 -C $CHANNEL_NAME -n mychaincode -c '{"Args":["insert", "158", "0123456789ABCDEF0123456789ABCDEF"]}' >& log.txt
set +x
cat log.txt
echo "Key: 158"
echo "Hash: 0123456789ABCDEF0123456789ABCDEF" 
echo

sleep 3

echo "---------- Query chaincode 1 -------------- "
set -x
peer chaincode query -C $CHANNEL_NAME -n mychaincode -c '{"Args":["query", "157"]}' >& log.txt
set +x
cat log.txt
echo "Input Key: 157"
echo

sleep 3

echo "---------- Query chaincode 2 -------------- "
set -x
peer chaincode query -C $CHANNEL_NAME -n mychaincode -c '{"Args":["query","158"]}' >& log.txt
set +x
cat log.txt
echo "Input Key: 158"
echo

echo "############# All GOOD, execution completed ###########  "
echo

