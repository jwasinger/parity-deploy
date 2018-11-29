#! /bin/bash
sudo rm -rf data/1/cache
sudo rm -rf data/1/chains
sudo rm -rf data/2/geth/
sudo rm -rf data/2/keystore/
geth init --datadir data/2 deployment/chain/geth.goerli.genesis.json
geth account import --datadir data/2 --password <(echo '') deployment/2/private.txt
