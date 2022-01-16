#!/bin/bash

CHANNEL_NAME="$1"
LANGUAGE="golang"
CC_SRC_PATH="github.com/chaincode/"


installChaincode() {
  	VERSION=${3:-1.0}
	echo $VERSION
  	VERSION="2.0"

  	set -x
  	peer chaincode install -n mychaincode -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
  	set +x
  	res=$?
  	cat log.txt
  	echo "====== Chaincode is installed on peer${PEER}.org${ORG} ======= "
	sleep 3
}


upgradeChaincode() {
  	set -x
  	peer chaincode upgrade -o orderer.intellicode.com:7050 -C $CHANNEL_NAME -n mychaincode -v 2.0 -c '{"Args":["init"]}' -P "AND ('Org1MSP.peer')" >& log.txt
  	set +x
  	res=$?
  	cat log.txt
  	echo "===== Chaincode is upgraded on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ====== "
	sleep 3
}

echo "----------- Installing chaincode on peer0.org1 ---------------"
installChaincode 0 1
echo
sleep 3

echo "----------- Upgrade chaincode on peer0.org1 ---------------"
upgradeChaincode 
echo
sleep 3


echo "---------- Insert chaincode  -------------- "
set -x
peer chaincode invoke -C $CHANNEL_NAME -n mychaincode -c '{"Args":["insert", "a", "10"]}' >& log.txt
set +x
cat log.txt
echo
sleep 3

echo "---------- Query chaincode -------------- "
set -x
peer chaincode query -C $CHANNEL_NAME -n mychaincode -c '{"Args":["query", "a"]}' >& log.txt
set +x
cat log.txt
echo

