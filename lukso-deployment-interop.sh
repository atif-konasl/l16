#!/bin/bash

function create_genesis {
	echo "Generating genesis.ssz..."
	rm -f ./vanguard/genesis.ssz
	./bin/genesis-state-gen \
	--output-json=./vanguard/genesis.json \
	--output-ssz=./vanguard/genesis.ssz \
	--num-validators=500 \
	--genesis-time=1623079120 \
 	--mainnet-config
}

function start_bootnode {
	echo "Strating bootnode..."
	nohup ./bin/bootnode \
	--discv5-port=3000 > ./vanguard/bootnode.txt 2>&1 </dev/null &
	disown
}

function stop_bootnode {
	echo "Stopping bootnode..."
	sudo kill $(sudo lsof -t -i:3000) &> /dev/null
}

function deploy_beacon_node {
	RPCPort=$(($1 + 4000))
	TracingPort=$(($1 + 14268))
	UDPPort=$(($1 + 12000))
	TCPPort=$(($1 + 13000))
	GRPCGateWayPort=$(($1 + 3500))
	
	nohup ./bin/beacon-chain \
	--chain-config-file=./config/config.yaml \
	--accept-terms-of-use \
	--disable-monitoring \
	--chain-id=4004181 \
	--network-id=4004181 \
	--interop-genesis-state=./vanguard/genesis.ssz \
	--interop-eth1data-votes \
	--force-clear-db \
	--datadir=$2 \
	--bootstrap-node="enr:-Ku4QDrXi5ZFR8rPXOtdZWsv8qI9WhVbqzPnwkqQbDIghlzTc_tr9Eih2ts7abs6621txx_a7MEoTUeNcxkSe_rC74kBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpD1pf1CAAAAAP__________gmlkgnY0gmlwhMCoAAOJc2VjcDI1NmsxoQMJJkVyUyLmiFv7anTZb9I0fPns7al_IjQJ1RqPcceEPYN1ZHCCC7g" \
	--http-web3provider=http://34.91.186.254:8545 \
	--deposit-contract=0x517E99D60093C628572E69b7e2B3619d28540127 \
	--contract-deployment-block=171 \
	--rpc-port=$RPCPort \
	--p2p-udp-port=$UDPPort \
	--p2p-tcp-port=$TCPPort \
	--grpc-gateway-port=$GRPCGateWayPort \
	--min-sync-peers=0 \
	--disable-blst=true \
	--lukso-network \
	--verbosity=debug > ~/Workspace/lukso/network-deployment/lukso-network/vanguard/vanguard.txt  2>&1 </dev/null & 
	disown
}

function deploy_beacon_nodes {
	echo "Deploying vanguard nodes..."
	baseDir=~/Workspace/lukso/network-deployment/lukso-network/vanguard/node-
	for (( i = 0; i < $1; i++ )); do
		datadir=${baseDir}${i}
		mkdir -p $datadir
		deploy_beacon_node $i $datadir
	done
}

function stop_beacon_nodes {
	echo "Stopping vanguard nodes..."
	for (( i = 0; i < $1; i++ )); do
		baseDir=~/Workspace/lukso/network-deployment/lukso-network/vanguard/node-
		baseDir+=$i
		sudo kill $(sudo lsof -t -i:$(($i + 4000))) &> /dev/null
		sleep 1
		rm -rf $baseDir
		echo "stop and clean up node - $i"
	done
}

function start_validator {
	echo "Starting validator node..."
	nohup ./bin/validator \
	--chain-config-file=./config/config.yaml \
	--accept-terms-of-use \
	--beacon-rpc-provider=localhost:4000 \
	--interop-num-validators=500 \
	--verbosity=debug \
	--force-clear-db > ./validator/validator.txt  2>&1 </dev/null & 
	disown
}

function stop_validator {
	echo "Stopping validator client..."
	sudo kill $(sudo lsof -t -i:7000) &> /dev/null
}

function deploy_pandora_node {
	echo "Starting pandora node..."
	basePath=~/Workspace/lukso/network-deployment/lukso-network/pandora
	baseDir=~/Workspace/lukso/network-deployment/lukso-network/pandora/chaindata
	mkdir -p $baseDir

	mkdir -p $baseDir/keystore
	cp -r $basePath/keystore/. $baseDir/keystore/.

	# run geth console
	./geth/bin/geth --datadir=$baseDir init $basePath/genesis.json &> /dev/null
	nohup ./bin/geth \
	--datadir=$baseDir \
	--networkid=1994 \
	--rpcaddr=0.0.0.0 \
	--rpcapi=admin,eth,net \
	--rpc \
	--rpccorsdomain="*" \
	--miner.etherbase=0xd7267865cfca20a1fff4d117a3478304a17f3660 \
	--verbosity=4 \
	--mine > $basePath/pandora.txt  2>&1 </dev/null &
	disown
}

function stop_pandora_node {
	echo "Stopping and cleaning pandora node..."

	baseDir=~/Workspace/lukso/network-deployment/lukso-network/pandora/chaindata
	rm -rf $baseDir
	sudo kill $(sudo lsof -t -i:30303) &> /dev/null
}

function start_orchestrator {
	echo "Strating orchestrator node...."
	nohup ./bin/bootnode \
}

function main {
	choiceloop=true;
	while $choiceloop; do
		echo "Choose..."

		echo "1. Create genesis ssz"
		echo "2. Start vanguard node"
		echo "3. Start validator node"
		echo "4. Stop vanguard node"
		echo "5. Stop validator node"
		echo "6. Start vanguard bootnode"
		echo "7. Stop vanguard bootnode"
		echo "8. Start pandora"
		echo "9. Stop pandora"
		echo "10. Exit"

		read choice

		if [ $choice -eq 1 ];then
			create_genesis
		elif [ $choice -eq 2 ]; then
			echo "Number of beacon nodes: "
			read startingNodes
			deploy_beacon_nodes $startingNodes
		elif [[ $choice -eq 3 ]]; then
			start_validator
		elif [[ $choice -eq 4 ]]; then
			echo "Number of beacon nodes to stop: "
			read numBeaconNode
			stop_beacon_nodes $numBeaconNode
		elif [[ $choice -eq 5 ]]; then
			stop_validator
		elif [[ $choice -eq 6 ]]; then
			start_bootnode
		elif [[ $choice -eq 7 ]]; then
			stop_bootnode
		elif [[ $choice -eq 8 ]]; then
			deploy_pandora_node
		elif [[ $choice -eq 9 ]]; then
			stop_pandora_node
		else {
			choiceloop=false
			echo "Finish..."
		}
		fi
	done
}

main
