# vlsmc
A VLSM Calculator
This is a VLSM calculator implemented in Bash.

# Notes
For a small CIDR like between 8 and 15, the script takes ages to produce output or hangs altogether. This is because of the efficiency of the algorithm used. Perhaps using bash to do this job is not suitable. Interacting with bash script and jq is relatively slow.

# Disclaimer
This project is for learning purposes only. It should not be used for a serious usage. But I am committed to improving/fixing issues that remain.

# Usage

Here is the usage information that the script produces.
```
$ vlsmc.sh 
VLSMC -- A VLSM Calculator
Written by Logan Won-Ki Lee, November 2021

Usage: vlsmc [ -n NETWORK ] [ -l [ ID,SIZE[:ID,SIZE]... ] ]
	-n: specify starting network
		NETWORK: starting network (eg. 192.168.10.0/24)
	-l: list of subnets
		ID: what you call your subnet (eg. MY_SUBNET)
		SIZE: size of hosts required per subnet
Example
vlsmc -n 192.168.10.0/24 -l 'KL,28:Perth,60:Sydney,12:Singapore,12:Perth-KL,2:Sydney-KL,2:Sinpapore-KL,2'
```
