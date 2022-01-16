#!/bin/bash

export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false
export IMAGE_TAG=1.4.8
export COMPOSE_PROJECT_NAME=intellicode


# Generate the needed certificates, the genesis block and start the network.
function networkUp() {
  LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)
  #echo $LOCAL_VERSION
  #echo $DOCKER_IMAGE_VERSION

  # generate artifacts if they don't exist
  #echo $COMPOSE_FILE
  #echo $IMAGETAG
  set -x
  /usr/local/bin/docker-compose -f $COMPOSE_FILE up -d 2>&1
  docker ps -a
  set +x 

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  else
    echo "Success to start docker-compose"
  fi

  sleep 3
  docker exec cli scripts/networkSetup.sh $CHANNEL_NAME 
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Starting Network is failed"
    exit 1
  fi
}


function runChaincode() {
  docker exec cli scripts/contractrun.sh $CHANNEL_NAME 

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Running ChainCode is failed"
    exit 1
  fi
}


function updateChaincode() {
  docker exec cli scripts/updateChaincode.sh $CHANNEL_NAME 

  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Running ChainCode is failed"
    exit 1
  fi
}


function networkDown() {
  /usr/local/bin/docker-compose -f $COMPOSE_FILE  down --volumes --remove-orphans

  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes.  Delete any ledger backups
    docker run -v $PWD:/tmp/kodit-network --rm hyperledger/fabric-tools:$IMAGETAG rm -Rf /tmp/kodit-network/ledgers-backup

    #Cleanup the chaincode containers and images
    clearContainers

    # remove orderer block and other channel configuration transactions and certs
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config 
  fi
}

function clearContainers() {
  #CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.mycc.*/) {print $1}')
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.mychaincode.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi

  #Cleanup images
  #DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.mycc.*/) {print $3}')
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.mychaincode.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}


# Generates Org certs using cryptogen tool
function generateCerts() {
  echo "##### Generate certificates using cryptogen tool #########"
  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi
  set -x
  cryptogen generate --config=./crypto-config.yaml
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
}


# Generate orderer genesis block, channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {
  echo "#########  Generating Orderer Genesis block ##############"
  echo "CONSENSUS_TYPE="$CONSENSUS_TYPE
  set -x
  if [ "$CONSENSUS_TYPE" == "solo" ]; then
    configtxgen -profile OrgsOrdererGenesis -channelID sys-channel -outputBlock ./channel-artifacts/genesis.block
  else
    echo "unrecognized CONSESUS_TYPE='$CONSENSUS_TYPE'. exiting"
  fi
  set +x
  res=$?
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

  echo "### Generating channel configuration transaction 'channel.tx' ###"
  set -x
  configtxgen -profile OrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  set +x
  res=$?
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo "#######    Generating anchor peer update for Org1MSP   ##########"
  set -x
  configtxgen -profile OrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
  set +x
  res=$?
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi
  echo "Complete setting the genesis block and channel"
}


# Obtain the OS and Architecture string, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

CLI_TIMEOUT=10
CLI_DELAY=3
CHANNEL_NAME="mychannel"
COMPOSE_FILE=docker-compose-cli.yaml
CONSENSUS_TYPE="solo"
LANGUAGE=golang
IMAGETAG="1.4.8"

MODE=$1
shift

#Create the network using docker compose
if [ "${MODE}" == "start" ]; then
  generateCerts
  generateChannelArtifacts
  networkUp
elif [ "${MODE}" == "run" ]; then ## run chaincode 
  runChaincode
elif [ "${MODE}" == "stop" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "restart" ]; then ## Restart the chaincode
  updateChaincode
else
  echo "Usage Error"
  exit 1
fi
