#!/bin/bash

# VLSMC -- A VLSM Calculator
# v-release-02
# Written by Logan Won-Ki Lee
# Uses code from TJ -- thanks a lot, man!
# November 2021

# we start with these...

# parse command line args and populate ARG_NET and ARG_LIST

ARG_NET=
ARG_LIST=
ARG_LIST_ARRAY=

# validate arg list
# ^([a-z|A-Z]+,[0-9]+:*)+$

usage () {
	echo "VLSMC -- A VLSM Calculator"
	echo "Written by Logan Won-Ki Lee, November 2021"
	echo
	echo "Usage: vlsmc [ -n NETWORK ] [ -l [ ID,SIZE[:ID,SIZE]... ] ]"
	echo "	-n: specify starting network"
	echo "		NETWORK: starting network (eg. 192.168.10.0/24)"
	echo "	-l: list of subnets"
	echo "		ID: what you call your subnet (eg. MY_SUBNET)"
	echo "		SIZE: size of hosts required per subnet"
	echo "Example"
	echo "vlsmc -n 192.168.10.0/24 -l 'KL,28:Perth,60:Sydney,12:Singapore,12:Perth-KL,2:Sydney-KL,2:Sinpapore-KL,2'"
}

exit_abnormal () {
	usage
	exit 1
}

while getopts ":n:l:" options
do
	case "${options}" in
		n)
			# implement regex checking of network address
			ARG_NET=${OPTARG}
			re_arg_net='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]+$'
			if ! [[ $ARG_NET =~ $re_arg_net ]]
			then
				echo "Error: wrong format when defining -n: starting network"
				echo
				exit_abnormal
			fi
			;;
		l)
			ARG_LIST=${OPTARG}
			#echo arg list "$ARG_LIST"
			re_arg_list='^([_[:alnum:]-]+,[0-9]+:*)+$'
			if ! [[ $ARG_LIST =~ $re_arg_list ]]
			then
				echo "Error: wrong format when defining -l: list of subnets"
				echo
				exit_abnormal
			fi
			;;
		:)
			echo "Error: -${OPTARG} requires an argument"
			exit_abnormal
			;;    
		*)
			exit_abnormal
			;;
				
	esac
done

# if no arg is given
if (( $OPTIND == 1 )); then
  exit_abnormal
fi

# starting network and subnet list must be provided
if [ -z "$ARG_NET" -o -z "$ARG_LIST" ]
then
  echo "Error: starting network and subnet list must be specified"
  exit_abnormal
fi

# test that we got -n and -l arg values
#echo network is "$ARG_NET"
#echo subnet list is "$ARG_LIST"

# convert ARG_LIST to array so we can loop through it
# and ad id,size pairs to JSON object.
ARG_LIST_ARRAY=($(echo $ARG_LIST | tr ':' ' '))
#echo arg list array is
#echo "${ARG_LIST_ARRAY[@]}"
#echo first item
#echo "${ARG_LIST_ARRAY[0]}"
#echo second item
#echo "${ARG_LIST_ARRAY[1]}"


#starting_network="192.168.10.0/24"		# this comes from the user's arg
starting_network="$ARG_NET"

# every .size and .id come from the user's arg
LIST_START=$(cat << EOF
[]
EOF
)

# might take a few seconds message
#echo might take a few seconds...
#echo IT MIGHT TAKE UP TO A MINUTE FOR THE RESULT TO COME UP!
#echo This is a learning project and not for professional use!
#echo This project uses my own algorithm which is not as efficient.
#echo Be patient!

#####################
# populate LIST_START
#####################

# loop through ARG_LIST_ARRAY and add .size and .id pairs to LIST_START
for i in "${ARG_LIST_ARRAY[@]}"
do
	__id__=$(cut -d ',' -f 1 <<< "$i")
	__size__=$(cut -d ',' -f 2 <<< "$i")
	
	# add to LIST_START
	LIST_START=$(jq --arg START_ITEM_ID "$__id__" --arg START_ITEM_SIZE "$__size__" '.+=[{id:$START_ITEM_ID, size:$START_ITEM_SIZE}]' <<< "$LIST_START")
done

# test
#echo updated LIST START
#echo "$LIST_START"

# PREVENT RUNNING FOR NOW
# UNTIL TESTING IS DONE.
#exit 0

# reverse sort by .size
LIST_START=$(jq '.|sort_by(.size|tonumber)|reverse' <<< "$LIST_START")
#echo reversed list start "$LIST_START"
# extract just the .id's and put them in an array
LIST_START_IDS=($(jq -r '.[]|.id' <<< "$LIST_START" | tr '\n' ' '))		# compare this with OCCUPIED_SUBNETS at the end of this script.
# extract just the .size's and put them in an array
LIST_START_SIZES=($(jq -r '.[]|.size' <<< "$LIST_START" | tr '\n' ' '))

# debug
#echo list start ids "${LIST_START_IDS[@]}"
#echo list start sizes "${LIST_START_SIZES[@]}"
#exit


#echo "${LIST_START_IDS[@]}"	# Perth KL Singapore Sydney Singapore-KL Sydney-KL Perth-KL
#echo "${LIST_START_IDS[0]}"	# Perth
#echo "${LIST_START_IDS[1]}"	# KL
#echo required sizes
#echo "${LIST_START_SIZES[@]}"	# 60 28 12 12 2 2 2
# let's convert required_hosts_sizes_plus_two to required_items.
#declare -i required_hosts_sizes=(12 12 28 60 2 2 2)		# this is what we get from user passing arguments.

# test other inputs
#declare -i required_hosts_sizes=(250 700 500 2 2 100)
declare -i required_hosts_sizes=("${LIST_START_SIZES[@]}")

declare -i required_hosts_sizes_plus_two=("${required_hosts_sizes[@]/%/+2}")

get_required_items () {
	#echo required hosts sizes plus two ${required_hosts_sizes_plus_two[@]}
	local required_items_not_sorted=()
	for s in "${required_hosts_sizes_plus_two[@]}"
	do
		local hosts_plus_two=$s
		local subnet=1
		
		while [ $subnet -lt $hosts_plus_two ]; do
		subnet=$(($subnet*2))
		done	
	
		required_items_not_sorted+=($subnet)
	done
	# now sort required_items_not_sorted
	required_items=($(echo "${required_items_not_sorted[@]}" | tr ' ' '\n' | sort -rn | tr '\n' ' '))
	#echo required items "${required_items[@]}"
}

# get required items array
get_required_items

# TJ's work
# convert IPv4 dotted decimal string to unsigned integer (32-bit)
quad2unsigned() { # quad2unsigned(string ipv4_dotted_decimal) => unsigned
 local quad="$1"
 local octet
 local -i address=0
 for pow in 24 16 8 0; do
  octet="${quad%%.*}"
  quad="${quad#*.}"
  address=$((2 ** pow * octet + address))
  #$debug && echo "quad2unsigned(): $pow $((2 ** pow)) $((2 ** pow * octet)) $address" >&2
 done
 printf "%d" $address
}

# convert 32-bit unsigned integer to IPv4 dotted decimal string
unsigned2quad() { # unsigned2quad(unsigned ipv4) => string
 local -i remains=$1
 local octet
 local dotted=""
 for pow in 24 16 8 0; do
  octet=$(( remains  >> pow ))
  dotted="${dotted}${octet}."
  remains=$(( remains - ( octet << pow )  ))
 done
 printf "%s" "${dotted%.*}"
}

# calculate network from an arbitrary address and prefix
unsigned2network() { # unsigned2network(unsigned address, unsigned prefix) => unsigned
 local -i addr="$1"
 local -i prefix="$2"
 printf "%d" $(( (addr >> ( 32 - prefix) << (32 - prefix) ) ))
}

# convert a network /prefix to the number of addresses it contains
prefix2range() { # prefix2range(unsigned prefix) => unsigned
 printf "%d" $(( 2 ** (32 - $1) ))
}

# convert a range (quantity of addresses) to the best-fit prefix
range2prefix() { # range2prefix(unsigned range) => unsigned
 local -i prefix=0
 while [[ $((2**prefix)) -lt $1 ]] && [[ $prefix -le 32 ]]; do
  prefix=$((prefix + 1))
 done
 printf "%d" $((32 - prefix))
}
# end TJ's work

LIST_END_CIDRS=()

# populate LIST_END_CIDRS from required_items
for s in "${required_items[@]}"
do
	# convert size to cidr
	_cidr=$(range2prefix $s)
	# add to LIST_END_CIDRS
	LIST_END_CIDRS+=($_cidr)
done

LIST_END_BASES_UNSIGNED=()
base=${starting_network%/*}
base_unsigned=$(quad2unsigned $base)

# populate LIST_END_BASES_UNSIGNED
# start from starting_network_unsigned
for s in "${!required_items[@]}"
do
	LIST_END_BASES_UNSIGNED+=($base_unsigned)
			
	# increment unsigned addr
	incr=${required_items[$s]}
	base_unsigned=$((base_unsigned+incr))
	
	# quit just before last item
	threshold=$((${#required_items[@]}-1))
	[ $s -eq $threshold ] && break	
done

LIST_END_BASES=()

# populate LIST_END_BASES
for u in "${LIST_END_BASES_UNSIGNED[@]}"
do
	_base=$(unsigned2quad $u)
	LIST_END_BASES+=($_base)
done

#############
# view result
#############
echo
echo starting network
echo "$starting_network"
echo

###########################################
# print occupied subnets' id, name and size
###########################################

for (( i=0; i<${#LIST_START_IDS[@]}; i++ ))
do
	# try fixed column sizes
	printf '%-20s: %-20s: %-15s\n' "${LIST_START_IDS[$i]}" "${LIST_END_BASES[$i]}/${LIST_END_CIDRS[$i]}" "${LIST_START_SIZES[$i]} hosts"
done

