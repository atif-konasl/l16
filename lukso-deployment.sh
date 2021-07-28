#!/bin/bash

function create_genesis_ssz {
	echo "##### Generating genesis.ssz #####"

	GENESIS_START=$(echo "$(date +%s)"+50 | bc)

	rm -f ./config/vanguard_genesis.ssz
	./bin/genesis-state-gen \
	--output-json=./config/vanguard_genesis.json \
	--output-ssz=./config/vanguard_genesis.ssz \
	--genesis-time=$GENESIS_START \
	--deposit-json-file=./config/keys/deposit_data-1627303130.json \
	--mainnet-config
}

function deploy_pandora {
	echo "###### Deploying pandora node ########"

	# run geth console
	./bin/pandora --datadir ./pandora/datadir init ./config/pandora-genesis.json &> /dev/null
	nohup ./bin/pandora --datadir=./pandora/datadir \
	 --networkid=4004181 \
	 --ethstats=proxima-centauri-atif:VIyf7EjWlR49@catalyst.silesiacoin.com \
	 --bootnodes=enode://9adad8b1cc7b9f49e898179497e324900fa86befad2f2f4cfad975e1d074e2c58474bfbbc9d380c8c4e4d39c0c3254fa0b8b3231bd11007044d5fcba8d10f0d3@35.198.116.152:30405 \
	 --port=30405 \
	 --rpc \
	 --rpcaddr=0.0.0.0 \
	 --rpcapi=eth,net \
	 --rpcport=8545 \
	 --http.corsdomain="*" \
	 --ws \
	 --ws.addr=0.0.0.0 \
	 --ws.api=admin,net,eth,debug,ethash,miner,personal,txpool,web3 \
	 --ws.port=8546 \
	 --ws.origins="*" \
	 --mine \
	 --miner.notify=ws://127.0.0.1:7878,http://127.0.0.1:7877 \
	 --miner.etherbase=91b382af07767Bdab2569665AC30125E978a0688 \
	 --verbosity=4 > ./pandora/pandora.txt  2>&1 & 
	 disown
}


function stop_pandora {
	echo "Stopping pandora node..."

	sudo kill $(sudo lsof -t -i:30405) &> /dev/null
	sleep 1
	rm -rf ./pandora/datadir
}


function deploy_vanguard {
	echo "####### Deploying vanguard node #######"
	
	nohup ./bin/beacon-chain \
	  --accept-terms-of-use \
	  --chain-id=4004181 \
	  --network-id=4004181 \
	  --genesis-state=./config/vanguard_genesis.ssz \
	  --force-clear-db \
	  --datadir=./vanguard/datadir \
	  --chain-config-file=./config/vanguard-config.yml \
	  --bootstrap-node="enr:-LK4QFYQgA-wif7ZFBZZe_WxhdgzolOXRfPYJSMVCKe-zcqgJWmNI1UlP3lpp5tZoivCWsZItYGakFUMDoIATefmmKMCh2F0dG5ldHOICABAAAELIASEZXRoMpBqqlfVAAAAAP__________gmlkgnY0gmlwhAoAAaqJc2VjcDI1NmsxoQKU5b-4C5Q7fv-nQfDzCTGzOM6H2jR-9MUIHro4gSnQD4N0Y3CCMsiDdWRwgi7g" \
	  --http-web3provider=http://127.0.0.1:8545 \
	  --deposit-contract=0x000000000000000000000000000000000000cafe \
	  --contract-deployment-block=0 \
	  --rpc-host="0.0.0.0" \
	  --monitoring-host="0.0.0.0" \
	  --verbosity=debug \
	  --min-sync-peers=0 \
	  --p2p-max-peers=10 \
	  --orc-http-provider=http://127.0.0.1:7877 \
	  --lukso-network > ./vanguard/vanguard.txt  2>&1 & 
	disown
}

function stop_vanguard {
	echo "###### Stopping vanguard #######"
	
	sudo kill $(sudo lsof -t -i:4000) &> /dev/null
	sleep 1
	sudo kill $(sudo lsof -t -i:12000) &> /dev/null
	sleep 1
	rm -rf ./vanguard/datadir
}



function start_validator {
	echo "##### Starting validator node #####"
	nohup ./bin/validator \
	  --datadir=./validator/datadir \
	  --accept-terms-of-use \
	  --beacon-rpc-provider=localhost:4000 \
	  --chain-config-file=./config/vanguard-config.yml \
	  --force-clear-db \
	  --verbosity=debug \
	  --pandora-http-provider=http://127.0.0.1:8545 \
	  --wallet-dir=./validator/wallet \
	  --wallet-password-file=./validator/password.txt \
	  --rpc \
	  --lukso-network > ./validator/validator.txt  2>&1 & 
	disown
}


function stop_validator {
	echo "###### Stopping validator client ######"
	sudo kill $(sudo lsof -t -i:7000) &> /dev/null
	sleep 1
	rm -rf ./validator/datadir
}

function start_orchestrator {
	echo "##### Starting orchestrator #######"
	./bin/orchestrator --force-clear-db \
		--accept-terms-of-use \
		--datadir=./orchestrator/datadir \
		--vanguard-grpc-endpoint=127.0.0.1:4000 \
		--http \
		--http.addr=0.0.0.0 \
		--http.port=7877 \
		--ws \
		--ws.addr=0.0.0.0 \
		--ws.port=7878 \
		--pandora-rpc-endpoint=ws://127.0.0.1:8546 \
		--verbosity=debug > ./orchestrator/orchestrator.txt  2>&1 & 
}


function stop_orchestrator {
	echo "###### Stopping orchestrator client ######"
	sudo kill $(sudo lsof -t -i:7877) &> /dev/null
}

function main {
	choiceloop=true;
	while $choiceloop; do
		echo "Choose..."

		echo "1. Create Genesis ssz"
		echo "2. Start pandora node"
		echo "3. Start orchestrator node"
		echo "4. Start vangaurd node"
		echo "5. Start validator node"
		echo "6. Stop validator node"
		echo "7. Stop pandora node"
		echo "8. Stop vanguard node"
		echo "9. Stop orchestrator node"
		echo "10. Exit"

		read choice

		if [ $choice -eq 1 ];then
			create_genesis_ssz
		elif [ $choice -eq 2 ]; then
			deploy_pandora
		elif [[ $choice -eq 3 ]]; then
			start_orchestrator
		elif [[ $choice -eq 4 ]]; then
			deploy_vanguard
		elif [[ $choice -eq 5 ]]; then
			start_validator
		elif [[ $choice -eq 6 ]]; then
			stop_validator
		elif [[ $choice -eq 7 ]]; then
			stop_pandora
		elif [[ $choice -eq 8 ]]; then
			stop_vanguard
		elif [[ $choice -eq 9 ]]; then
			stop_orchestrator
		else {
			choiceloop=false
			echo "Finish..."
		}
		fi
	done
	
}

main
