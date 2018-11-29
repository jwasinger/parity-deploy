#! /bin/bash

kill -9 $(cat geth_pid.txt)
kill -9 $(cat parity_pid.txt)
