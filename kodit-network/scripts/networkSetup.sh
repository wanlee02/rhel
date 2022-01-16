#!/bin/bash

CHANNEL_NAME="$1"
LANGUAGE="golang"

CC_SRC_PATH="github.com/chaincode/"
#CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/"


createChannel() {
	setGlobals 0 1

        set -x
	peer channel create -o orderer.intellicode.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
        set +x
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
}

setGlobals() {
  	PEER=$1
  	ORG=$2
  	if [ $ORG -eq 1 ]; then
    		CORE_PEER_LOCALMSPID="Org1MSP"
    		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.intellicode.com/users/Admin@org1.intellicode.com/msp
    		if [ $PEER -eq 0 ]; then
      			CORE_PEER_ADDRESS=peer0.org1.intellicode.com:7051
    		else
      			CORE_PEER_ADDRESS=peer1.org1.intellicode.com:8051
    		fi
  	else
    		echo "================== ERROR !!! ORG Unknown =================="
    		exit 1
  	fi
}

verifyResult() {
  	if [ $1 -ne 0 ]; then
    		echo "ERROR: !!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    	exit 1
  	fi
}


joinChannel () {
  	ORG=1
    	for peer in 0 1; do
  		PEER=$peer
  		setGlobals $PEER $ORG
		set -x
  		peer channel join -b $CHANNEL_NAME.block >&log.txt
  		set +x
  		res=$?
  		cat log.txt
  		verifyResult $res "peer${peer}.org1 has failed to join channel '$CHANNEL_NAME' "
		echo "===== peer${peer}.org1 joined channel '$CHANNEL_NAME' ===== "
		sleep 3
    	done
}


updateAnchorPeers() {
  	PEER=$1
  	ORG=$2
  	setGlobals $PEER $ORG

    	set -x
    	peer channel update -o orderer.intellicode.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    	set +x
    	res=$?
  	cat log.txt
  	verifyResult $res "Anchor peer update failed"
  	echo "====== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ======= "
  	sleep 3 
}


installChaincode() {
  	PEER=$1
  	ORG=$2
  	setGlobals $PEER $ORG
  	VERSION=${3:-1.0}

  	set -x
  	peer chaincode install -n mychaincode -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
  	set +x
  	res=$?
  	cat log.txt
  	verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has failed"
  	echo "====== Chaincode is installed on peer${PEER}.org${ORG} ======= "
}


instantiateChaincode() {
  	PEER=$1
  	ORG=$2
  	setGlobals $PEER $ORG
  	VERSION=${3:-1.0}

    	set -x
    	peer chaincode instantiate -o orderer.intellicode.com:7050 -C $CHANNEL_NAME -n mychaincode -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init"]}' -P "AND ('Org1MSP.peer')" >&log.txt
    	set +x
    	res=$?
  	cat log.txt
  	verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
  	echo "====== Chaincode is instantiated on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ====== "
}


sleep 3
echo
echo "----------- Creating channel -------------"
createChannel
echo
sleep 3

echo "----------- Having all peers join the channel ----------------"
joinChannel
echo
sleep 3

#echo "Updating anchor peers for org1..."
#updateAnchorPeers 0 1

echo "----------- Installing chaincode  ---------------"
installChaincode 0 1
echo
sleep 5

echo "----------- Instantiating chaincode --------------- "
instantiateChaincode 0 1
echo

