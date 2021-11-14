# vlsmc
A VLSM Calculator

This is a VLSM calculator implemented in Bash.

# Notes
For a small CIDR like between 8 and 15, the script takes ages to produce output or hangs altogether. This is because of the efficiency of the algorithm used. Perhaps using bash to do this job is not suitable. Interacting with bash script and jq is relatively slow.

This script is, of course, to be run inside bash. You also need bc and jq.

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
# Demo
1.

## Command
`vlsmc.sh -n 165.23.208.0/20 -l A,250:B,700:C,500:D,100:X,2:Y,2`

```
$ ./vlsmc.sh -n 165.23.208.0/20 -l A,250:B,700:C,500:D,100:X,2:Y,2
might take a few seconds...
IT MIGHT TAKE UP TO A MINUTE FOR THE RESULT TO COME UP!
This is a learning project and not for professional use!
This project uses my own algorithm which is not as efficient.
Be patient!

starting network
165.23.208.0/20

B                   : 165.23.208.0/22     : 700 hosts      
C                   : 165.23.212.0/23     : 500 hosts      
A                   : 165.23.214.0/24     : 250 hosts      
D                   : 165.23.215.0/25     : 100 hosts      
Y                   : 165.23.215.128/30   : 2 hosts        
X                   : 165.23.215.132/30   : 2 hosts   
```

2.
