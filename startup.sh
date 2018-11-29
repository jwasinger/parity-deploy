#! /bin/bash

rm -f parity.log
rm -f deployment/chain/parity.goerli.genesis.json
rm -f deployment/chain/geth.goerli.genesis.json
rm -rf deployment/1/goerli
rm -f deployment/1/authority.toml
rm -rf data/2

kill -9 $(cat geth_pid.txt)
kill -9 $(cat parity_pid.txt)

echo "configuring parity"

../parity-ethereum/target/debug/parity --chain deployment/chain/parity.goerli.genesis.json.ref account new  --keys-path  ./deployment/1/ --password ./deployment/1/password > ./deployment/1/address.txt

EXTRA_DATA="0x0000000000000000000000000000000000000000000000000000000000000000"
for x in $(seq 1 2 ); do
	VALIDATOR=$(cat deployment/$x/address.txt | sed -e "s/0x//g" )
	EXTRA_DATA="${EXTRA_DATA}${VALIDATOR}"
done

EXTRA_DATA="${EXTRA_DATA}0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

cat deployment/1/authority.toml.ref | sed -e "s|AUTHORITY|$(cat deployment/1/address.txt)|g" > deployment/1/authority.toml
cat deployment/chain/parity.goerli.genesis.json.ref | sed -e "s/EXTRA_DATA/$EXTRA_DATA/g" > deployment/chain/parity.goerli.genesis.json
cat deployment/chain/geth.goerli.genesis.json.ref | sed -e "s/EXTRA_DATA/$EXTRA_DATA/g" > deployment/chain/geth.goerli.genesis.json

echo "configuring geth"

etherbase="$(cat deployment/2/address.txt)"
nodekeyhex="648ae4e80c2e5227cc628fe1d5a9f9382d6bf9f7085ca2f90da90fb2ff19dace"
go_binary="/home/ewasm/go/src/github.com/ethereum/go-ethereum/build/bin/geth"

echo "geth init"
/home/ewasm/go/src/github.com/ethereum/go-ethereum/build/bin/geth init --datadir data/2 deployment/chain/geth.goerli.genesis.json

echo "geth account import"
/home/ewasm/go/src/github.com/ethereum/go-ethereum/build/bin/geth account import --datadir data/2 --password <(echo '') deployment/2/private.txt

cat deployment/chain/geth.goerli.genesis.json.ref | sed -e "s/EXTRA_DATA/$EXTRA_DATA/g" > deployment/chain/geth.goerli.genesis.json

echo "starting geth"

nohup /home/ewasm/go/src/github.com/ethereum/go-ethereum/build/bin/geth --datadir ./data/2 --etherbase "$etherbase" --nodekeyhex "648ae4e80c2e5227cc628fe1d5a9f9382d6bf9f7085ca2f90da90fb2ff19dace" --rpc --rpcapi "web3,net,eth,debug" --rpcvhosts=* --rpccorsdomain "*" --mine --miner.threads 1 --port 30303 --unlock "$etherbase" --password ./deployment/2/password --networkid 6284 --syncmode "full" --vmodule "eth/downloader=12,consensus/clique=12" > geth.log 2>&1 &

echo $! > geth_pid.txt

echo "starting parity"

nohup ../parity-ethereum/target/debug/parity --keys-path /home/ewasm/projects/parity-deploy-old/deployment/1/ --chain /home/ewasm/projects/parity-deploy-old/deployment/chain/parity.goerli.genesis.json --config /home/ewasm/projects/parity-deploy-old/deployment/1/authority.toml -d ./data/1 --force-sealing --jsonrpc-port=8547 --port 30304 --engine-signer $(cat deployment/1/address.txt) -l engine=trace > parity.log 2>&1 &

echo $! > parity_pid.txt
