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
-n sets the starting network block.

-l sets the list of required subnets: ID,SIZE pairs. Each pair is separated by :.

# Demo

## First example
`vlsmc.sh -n 165.23.208.0/20 -l A,250:B,700:C,500:D,100:X,2:Y,2`

This says: set starting network block to 165.23.208.0/20 and define the list of requirements as:
|Subnet ID|Required host size|
|---|---|
|A|250|
|B|700|
|C|500|
|D|100|
|X|2|
|Y|2|

Here's the output that contains the subnet ID's with their network address.

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

## Second example
Here's the command:

`vlsmc.sh -n 192.168.10.0/24 -l 'KL,28:Perth,60:Sydney,12:Singapore,12:Perth-KL,2:Sydney-KL,2:Sinpapore-KL,2'`

This sets the starting network block to 192.168.10.0/24 and the list of required subnets as:

|Subnet ID|Required host size|
|---|---|
|KL|28|
|Perth|60|
|Sydney|12|
|Singapore|12|
|Perth-KL|2|
|Sydney-KL|2|
|Singapore-KL|2|

And here's the output:

```
$ ./vlsmc.sh -n 192.168.10.0/24 -l 'KL,28:Perth,60:Sydney,12:Singapore,12:Perth-KL,2:Sydney-KL,2:Sinpapore-KL,2'
might take a few seconds...
IT MIGHT TAKE UP TO A MINUTE FOR THE RESULT TO COME UP!
This is a learning project and not for professional use!
This project uses my own algorithm which is not as efficient.
Be patient!

starting network
192.168.10.0/24

Perth               : 192.168.10.0/26     : 60 hosts       
KL                  : 192.168.10.64/27    : 28 hosts       
Singapore           : 192.168.10.96/28    : 12 hosts       
Sydney              : 192.168.10.112/28   : 12 hosts       
Sinpapore-KL        : 192.168.10.128/30   : 2 hosts        
Sydney-KL           : 192.168.10.132/30   : 2 hosts        
Perth-KL            : 192.168.10.136/30   : 2 hosts     
```

## Third example
`vlsmc.sh -n 192.168.1.0/24 -l LAN1,29:LAN2,21:LAN3,12:LAN4,8:WAN1,2:WAN2,2:WAN3,2:WAN4,2`

This sets the starting network block as 192.168.1.0/24 and the list of required subnets as:

|Subnet ID|Required host size|
|---|---|
|LAN1|29|
|LAN2|21|
|LAN3|12|
|LAN4|8|
|WAN1|2|
|WAN2|2|
|WAN3|2|
|WAN4|2|

Here's the output:

```
$ ./vlsmc.sh -n 192.168.1.0/24 -l LAN1,29:LAN2,21:LAN3,12:LAN4,8:WAN1,2:WAN2,2:WAN3,2:WAN4,2
might take a few seconds...
IT MIGHT TAKE UP TO A MINUTE FOR THE RESULT TO COME UP!
This is a learning project and not for professional use!
This project uses my own algorithm which is not as efficient.
Be patient!

starting network
192.168.1.0/24

LAN1                : 192.168.1.0/27      : 29 hosts       
LAN2                : 192.168.1.32/27     : 21 hosts       
LAN3                : 192.168.1.64/28     : 12 hosts       
LAN4                : 192.168.1.80/28     : 8 hosts        
WAN4                : 192.168.1.96/30     : 2 hosts        
WAN3                : 192.168.1.100/30    : 2 hosts        
WAN2                : 192.168.1.104/30    : 2 hosts        
WAN1                : 192.168.1.108/30    : 2 hosts 
```

## Fourth example
`vlsmc.sh -n 172.168.0.0/16 -l VLAN1,240:VLAN2,200:LAN1,150:LAN2,50:WAN1,2:WAN2,2`

This sets the starting network block as 172.168.0.0/16 and the list of required subnets as:

|Subnet ID|Required host size|
|---|---|
|VLAN1|240|
|VLAN2|200|
|LAN1|150|
|LAN2|50|
|WAN1|2|
|WAN2|2|

