#!/bin/bash

# VLSMC -- A VLSM Calculator
# v-release-01
# Written by Logan Won-Ki Lee
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
echo might take a few seconds...
echo IT MIGHT TAKE UP TO A MINUTE FOR THE RESULT TO COME UP!
echo This is a learning project and not for professional use!
echo This project uses my own algorithm which is not as efficient.
echo Be patient!

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

#required_items=(64 32 16 16 4 4 4)
#starting_network="192.168.10.0/24"		# this comes from the user's arg

# let's try some different required items list.
#required_items=(1024 512 256 128 4 4)
#starting_network="165.23.208.0/20"

# if there is no item then quit!
[ "${#required_items[@]}" -lt 1 ] && echo no items! && exit 1

VLSM_MAP=$(cat << EOF
[
	{
		"block_id": "$starting_network",
		"block_parent_id": "root",
		"current_index": 0,
		"child_sum": 0,
		"block_cidr": "",
		"block_size": "",
		"child_cidr": "",
		"child_size": "",
		"subnets": []
	}
]
EOF
)

TRACKER=$(cat << EOF
{
	"current_block_id": "",
	"current_item_index": 0
}
EOF
)

OCCUPIED_SUBNETS=$(cat << EOF
[]
EOF
)

# set current item index -- implement this!
set_current_item_index () {
	local index_="$1"
	TRACKER=$(jq --arg NEW_ITEM_INDEX "$index_" '.current_item_index=$NEW_ITEM_INDEX' <<< "$TRACKER")
	#echo set current item index
	#echo "$TRACKER"
}
# test
#set_current_item_index 1
#set_current_item_index 0

get_current_item_index () {
	local index_=$(jq -r '"\(.current_item_index)"' <<< "$TRACKER")
	echo $index_
}

# set current block id so we know which block to work on next.
# would be useful to write this as a function.
set_current_block_id () {
	local block_="$1"
	# set current_block_id to block_
	TRACKER=$(jq --arg CURRENT_BLOCK_ID "$block_" '.current_block_id=$CURRENT_BLOCK_ID' <<< "$TRACKER")
	#echo "$TRACKER"
}

# set current block id to starting network to start with
set_current_block_id "$starting_network"
# test
#echo "$TRACKER"

# get current block id
get_current_block_id () {
	local got_current_block_id_from_tracker_=$(jq -r '"\(.current_block_id)"' <<< "$TRACKER")
	echo "$got_current_block_id_from_tracker_"
}

# test
current_block_id_=$(get_current_block_id)
#echo current block id: "$current_block_id_"

# utility functions: set/get current index
set_current_index_of_current_block () {
	local _index=$1
	local _current_block_id=$(get_current_block_id)
	VLSM_MAP=$(jq --arg BLOCK_ID "$_current_block_id" --arg INDEX "$_index" '[.[] | select(.block_id==$BLOCK_ID).current_index=$INDEX]' <<< "$VLSM_MAP")
	
	# test
	#echo set current index
	#echo "$VLSM_MAP"
}

get_current_index_of_current_block () {
	local _current_block_id=$(get_current_block_id)
	local _index=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.current_index)"' <<< "$VLSM_MAP")
	echo $_index
}
# test: set current index to 999 then retrieve it to confirm.
#set_current_index_of_current_block 999
#echo get current index 999
#get_current_index_of_current_block
# reset
#echo reset current index to zero
#set_current_index_of_current_block 0

# utility functions
# change it so that it avoids setting global variable(s).
convert_cidr_to_hosts_size () {
	local cidr=$1
	local size=$((2**(32-$cidr)))
	echo $size
}

convert_hosts_size_to_cidr () {
	local size=$1
	local power=0
	local dummy=1
	while [ $size -ne $dummy ]; do
		power=$(($power+1))
		dummy=$((2**$power))		
	done

	local cidr=$((32-$power))
	echo $cidr
}

# make them into a function
calculate_block_and_child_cidr_and_size () {
	local block_=$(get_current_block_id)
	block_cidr=${block_#*/}
	block_size=$(convert_cidr_to_hosts_size $block_cidr)
	local i_=$(get_current_item_index)
	child_size=${required_items[$i_]}
	child_cidr=$(convert_hosts_size_to_cidr $child_size)
}

# first we need to fill in block_cidr, block_size, child_cidr and child_size for the MAIN block.
# then we need to map the MAIN block.
#block_cidr=${starting_network#*/}

# use utility functions above.
#convert_cidr_to_hosts_size $block_cidr
#block_size=$size

#child_size=${required_items[0]}
#convert_hosts_size_to_cidr $child_size
#child_cidr=$cidr

# need to call calculate_block_and_child_cidr_and_size here so that we can set fields for the current block.
calculate_block_and_child_cidr_and_size

# select current block id
# this variable will be shared in current block context.
block_id__=$(get_current_block_id)

# test
#echo block cidr $block_cidr
#echo block size $block_size
#echo child cidr $child_cidr
#echo child size $child_size

# fill in initial details
VLSM_MAP=$(jq --arg BLOCK_ID "$block_id__" --arg BLOCK_CIDR "$block_cidr" '[.[] | select(.block_id==$BLOCK_ID).block_cidr=$BLOCK_CIDR]' <<< "$VLSM_MAP")
VLSM_MAP=$(jq --arg BLOCK_ID "$block_id__" --arg BLOCK_SIZE "$block_size" '[.[] | select(.block_id==$BLOCK_ID).block_size=$BLOCK_SIZE]' <<< "$VLSM_MAP")
VLSM_MAP=$(jq --arg BLOCK_ID "$block_id__" --arg CHILD_CIDR "$child_cidr" '[.[] | select(.block_id==$BLOCK_ID).child_cidr=$CHILD_CIDR]' <<< "$VLSM_MAP")
VLSM_MAP=$(jq --arg BLOCK_ID "$block_id__" --arg CHILD_SIZE "$child_size" '[.[] | select(.block_id==$BLOCK_ID).child_size=$CHILD_SIZE]' <<< "$VLSM_MAP")

# test
#echo "$VLSM_MAP"

# test map function
# first, another utility function
# increment network address given increment size.
increment_net_addr () {
	local net=$1
	local incr=$2
	local cidr=${starting_network#*/}
	
	# different cases for three cidr ranges:
	# 1. cidr>=24
	# 2. 16<=cidr<24
	# 3. 8<=cidr<16
	if [ $cidr -ge 24 ]
	then
		local replace=$(cut -d "." -f 4 <(echo $net))         # value of the fourth octet
		local replace_with=$(($replace+$incr))                   # fourth octet + incr
		next_net=${net%$replace}$replace_with           # incremented network address
	elif [ $cidr -ge 16 -a $cidr -lt 24 ]
	then
		# retrieve third and fourth octets
		local third=$(cut -d '.' -f 3 <<< "$net")
		local fourth=$(cut -d '.' -f 4 <<< "$net")
		local fourth=${fourth%/*}

		#echo $third
		#echo $fourth

		# convert third and fourth octet decimal values to binary
		# with 8 digits
		local third_binary=$(bc <<< "obase=2;$third")
		local fourth_binary=$(bc <<< "obase=2;$fourth")
		
		# pad them with zeros from the left so they are 8 bits long.
		local third_binary=$(printf "%08d" $third_binary)
		local fourth_binary=$(printf "%08d" $fourth_binary)

		#echo $third_binary
		#echo $fourth_binary
		
		# concatenate third binary string and fourth binary string
		local long_binary_string=$third_binary$fourth_binary
		
		#echo $long_binary_string
		
		# convert long binary string to decimal again
		local long_decimal=$(bc <<< "ibase=2;$long_binary_string")
		
		# add required_item to long_decimal
		local long_decimal_next=$((long_decimal+incr))
		
		# convert long decimal next back to binary
		local long_binary_next=$(bc <<< "obase=2;$long_decimal_next")
		long_binary_next=$(printf "%16s" $long_binary_next | tr ' ' '0')	# now it pads correctly
		
		#echo $long_binary_next
		
		# cut long binary next into two 8 bits pieces
		local next_eight_bits1=${long_binary_next:0:8}
		local next_eight_bits2=${long_binary_next:8:8}
		
		#echo $next_eight_bits1
		#echo $next_eight_bits2
		
		# convert both next eight bits back to decimal
		# these are the final decimal third and fourth octets for
		# the incremented next subnet ip.
		local next_third=$(bc <<< "ibase=2;$next_eight_bits1")
		local next_fourth=$(bc <<< "ibase=2;$next_eight_bits2")
		
		#echo $next_third $next_fourth	# they are 212 0
		
		# now let's piece together the complete next subnet ip
		# from starting network addr.
		local left=$(cut -d '.' -f 1 <<< "$net" ).$(cut -d '.' -f 2 <<< "$net").
		local right=${next_third}.${next_fourth}
		next_net=${left}${right}	
	elif [ $cidr -ge 8 -a $cidr -lt 16 ]
	then
		# retrieve second, third and fourth octets
		local second=$(cut -d '.' -f 2 <<< "$net")
		local third=$(cut -d '.' -f 3 <<< "$net")
		local fourth=$(cut -d '.' -f 4 <<< "$net")
		local fourth=${fourth%/*}

		#echo $third
		#echo $fourth

		# convert second, third and fourth octet decimal values to binary
		# with 8 digits
		local second_binary=$(bc <<< "obase=2;$second")
		local third_binary=$(bc <<< "obase=2;$third")
		local fourth_binary=$(bc <<< "obase=2;$fourth")
		
		# pad them with zeros from the left so they are 8 bits long.
		local second_binary=$(printf "%08d" $second_binary)
		local third_binary=$(printf "%08d" $third_binary)
		local fourth_binary=$(printf "%08d" $fourth_binary)

		#echo $third_binary
		#echo $fourth_binary
		
		# concatenate second binary, third binary string and fourth binary string
		local long_binary_string=$second_binary$third_binary$fourth_binary
		
		#echo $long_binary_string
		
		# convert long binary string to decimal again
		local long_decimal=$(bc <<< "ibase=2;$long_binary_string")
		
		# add required_item to long_decimal
		local long_decimal_next=$((long_decimal+incr))
		
		# convert long decimal next back to binary
		local long_binary_next=$(bc <<< "obase=2;$long_decimal_next")
		long_binary_next=$(printf "%24s" $long_binary_next | tr ' ' '0')	# now it pads correctly
		
		#echo $long_binary_next
		
		# cut long binary next into two 8 bits pieces
		local next_eight_bits1=${long_binary_next:0:8}
		local next_eight_bits2=${long_binary_next:8:8}
		local next_eight_bits3=${long_binary_next:16:8}
		
		#echo $next_eight_bits1
		#echo $next_eight_bits2
		
		# convert all three next eight bits back to decimal
		# these are the final decimal second, third and fourth octets for
		# the incremented next subnet ip.
		local next_second=$(bc <<< "ibase=2;$next_eight_bits1")
		local next_third=$(bc <<< "ibase=2;$next_eight_bits2")
		local next_fourth=$(bc <<< "ibase=2;$next_eight_bits3")
		
		#echo $next_second $next_third $next_fourth
		
		# now let's piece together the complete next subnet ip
		# from starting network addr.
		local left=$(cut -d '.' -f 1 <<< "$net" ).
		local right=${next_second}.${next_third}.${next_fourth}
		next_net=${left}${right}			
	fi
}

map_network_with_subnets () {
	local block_id__=$(get_current_block_id)
	local parent_network_cidr=$1
	local required_subnet_hosts=$2
	local parent_network_addr=$3

	#convert_cidr_to_hosts_size $parent_network_cidr
	#parent_network_hosts=$size
	parent_network_hosts=$(convert_cidr_to_hosts_size $parent_network_cidr)

	#convert_hosts_size_to_cidr $required_subnet_hosts
	#required_subnet_cidr=$cidr
	required_subnet_cidr=$(convert_hosts_size_to_cidr $required_subnet_hosts)

	number_of_subnets=$(($parent_network_hosts/$required_subnet_hosts))
	#echo $number_of_subnets many subnets.

	children_subnets=()
	subnet_network_addr=$parent_network_addr

	for (( c=1; c<=$number_of_subnets; c++ )); do
		line=${subnet_network_addr}/${required_subnet_cidr}
		children_subnets+=($line)

		# we don't need hat anymore
		#hat=${parent_network_addr}/${parent_network_cidr}

		increment_net_addr $subnet_network_addr $required_subnet_hosts
		subnet_network_addr=$next_net
	done

	# print results
	#echo -e $hat
	#echo "${children_subnets[@]}" | tr ' ' '\n'

	# loop through all elements of subnets of current block
	# then add each of them to the .subnets json map.
	for s in "${children_subnets[@]}"; do
		VLSM_MAP=$(jq --arg BLOCK_ID "$block_id__" --arg SUBNET_CURRENT_BLOCK "$s" '[.[] | select(.block_id==$BLOCK_ID).subnets+=[{"name": $SUBNET_CURRENT_BLOCK}]]' <<< "$VLSM_MAP")

	done

	# test
	#echo "$VLSM_MAP"
}

# map the MAIN block.
# maybe a function is useful here-after?
set_parameters_for_mapping () {
	local block_id_=$(get_current_block_id)
	CURRENT_BLOCK_CIDR=${block_id_##*/}

	local item_index_=$(get_current_item_index)
	CURRENT_ITEM_SIZE=${required_items[$item_index_]}
	
	CURRENT_BLOCK_NET_ADDR=${block_id_%/*}

	#echo current block cidr: $CURRENT_BLOCK_CIDR
	#echo current item size: $CURRENT_ITEM_SIZE
	#echo current block net addr: $CURRENT_BLOCK_NET_ADDR
}

# set up parameters before mapping current block.
set_parameters_for_mapping

# now map the MAIN block.
map_network_with_subnets $CURRENT_BLOCK_CIDR $CURRENT_ITEM_SIZE $CURRENT_BLOCK_NET_ADDR

# test map_network_with_subnets function
#map_network_with_subnets 24 64 192.168.10.0		# will it work the first time? :p
#map_network_with_subnets 26 32 192.168.10.64


###########################################################
# flags
# logic seem promising but needs implementing to main code.
###########################################################

# utility function
get_subnet_of_index () {
	local _current_block_id="$1"
	local _index="$2"
	local _subnet=$(jq -r --arg BLOCK_ID "$_current_block_id" --arg INDEX "$_index" '.[] | select(.block_id==$BLOCK_ID) | .subnets[$INDEX|tonumber] | .name' <<< "$VLSM_MAP")
	echo "$_subnet"
}
# test
#echo 2nd subnet:
#get_subnet_of_index $(get_current_block_id) 1

# another utility function
update_child_sum () {
	local _current_block_id=$(get_current_block_id)
	local _child_sum=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | .child_sum' <<< "$VLSM_MAP")
	local _child_size=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | .child_size' <<< "$VLSM_MAP")
	# test
	#echo child sum $_child_sum
	#echo child size $_child_size
	
	# sum it.
	_child_sum=$((_child_sum+_child_size))
	#echo updated child sum "$_child_sum"	
	
	# update child sum now
	VLSM_MAP=$(jq --arg BLOCK_ID "$_current_block_id" --arg SUM "$_child_sum" '[.[] | select(.block_id==$BLOCK_ID).child_sum=$SUM]' <<< "$VLSM_MAP")	
}
# test
#update_child_sum
#echo after updating child sum:
#echo "$VLSM_MAP"
#echo tracker:
#echo "$TRACKER"

# first we can define commit_first_subnet which can be reused.
commit_first_subnet () {
	# update child sum
	update_child_sum
		
	# commit current subnet
	local first_subnet=$(get_subnet_of_index $(get_current_block_id) 0)
	OCCUPIED_SUBNETS=$(jq --arg ITEM "$first_subnet" '.+=[{"name":$ITEM}]' <<< "$OCCUPIED_SUBNETS")
	#echo occupied subnets:
	#echo "$OCCUPIED_SUBNETS"
	
	# update current item index to next one.
	local _current_item_index=$(get_current_item_index)
	_current_item_index=$((_current_item_index+1))
	set_current_item_index $_current_item_index
	
	#echo current item index after commit first subnet "$_current_item_index"
	
	#echo commit!
}

# commit first subnet of MAIN block
commit_first_subnet

# utility function
# commit current subnet of current block
commit_current_subnet () {
	local _current_index=$(get_current_index_of_current_block)
	#echo current index $_current_index
	local _current_subnet=$(get_subnet_of_index $(get_current_block_id) $_current_index)
	OCCUPIED_SUBNETS=$(jq --arg ITEM "$_current_subnet" '.+=[{"name":$ITEM}]' <<< "$OCCUPIED_SUBNETS")
	#echo occupied subnets:
	#echo "$OCCUPIED_SUBNETS"
}

IS_FULL=001
IS_NOT_FULL=002
IF_ITEM=003
IF_NO_ITEM=004
IS_DIVIDE=005
IS_NOT_DIVIDE=006
CURRENT_FLAG=
commit_count_limit=0

CREATED_BLOCK=100
IS_BLOCK_FULL=101
IS_BLOCK_NOT_FULL=102
IF_BLOCK_ITEM=103
IF_BLOCK_NO_ITEM=104
IS_BLOCK_DIVIDE=105
IS_BLOCK_NOT_DIVIDE=106
PARENT_IS_MAIN=107
PARENT_IS_NOT_MAIN=108

# MAIN tests
check_FULL () {
	local _current_block_id=$(get_current_block_id)
	local _block_size=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.block_size)"' <<< "$VLSM_MAP")
	local _child_sum=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.child_sum)"' <<< "$VLSM_MAP")
	
	# test
	#echo block size "$_block_size"
	#echo child sum "$_child_sum"
	
	if [ $_block_size -eq $_child_sum ] 
	then
		CURRENT_FLAG=$IS_FULL
	else
		CURRENT_FLAG=$IS_NOT_FULL
	fi
	
	# test
	#echo MAIN block is $CURRENT_FLAG
	
	# remove this
	#CURRENT_FLAG=$IS_FULL
}
# start with IS_NOT_FULL
#check_FULL

update_INDEX () {
	# try updating child sum here instead of inside if IS_NOT_DIVIDE
	update_child_sum

	local _current_item_index=$(get_current_item_index)
	local _current_index=$(get_current_index_of_current_block)
	
	# increment current item index and current index by one.
	#_current_item_index=$((_current_item_index+1))	# not here!!!
	_current_index=$((_current_index+1))

	# test
	#echo updated current item index $_current_item_index
	#echo updated current index of current block $_current_index
	
	# qualifier
	local _total_number_of_items=${#required_items[@]}
	#echo total number of items $_total_number_of_items
	if [ $_current_item_index -le $((_total_number_of_items-1)) ]
	then
		#set_current_item_index $_current_item_index	# not here!
		set_current_index_of_current_block $_current_index
		CURRENT_FLAG=$IF_ITEM
	else
		CURRENT_FLAG=$IF_NO_ITEM
	fi
	
	# test
	#echo current flag after update_INDEX $CURRENT_FLAG
	
	# remove this
	#CURRENT_FLAG=$IF_ITEM
	#[ $commit_count_limit -eq 2 ] && CURRENT_FLAG=$IF_NO_ITEM
}

check_DIVIDE () {
	local _current_block_id=$(get_current_block_id)
	local _child_size_of_current_block=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.child_size)"' <<< "$VLSM_MAP")
	
	#echo current block id inside check_DIVIDE "$_current_block_id"
	
	# test
	#echo child size of current block $_child_size_of_current_block
	
	local _current_item_index=$(get_current_item_index)
	local _current_item=${required_items[$_current_item_index]}

	#echo child size of current block "$_child_size_of_current_block"
	#echo current item index inside check_DIVIDE "$_current_item_index"
	#echo current item "$_current_item"
	
	#test
	#echo current item index $_current_item_index
	#echo current_item $_current_item
	
	if [ $_child_size_of_current_block -gt $_current_item ]
	then
		CURRENT_FLAG=$IS_DIVIDE
	else
		CURRENT_FLAG=$IS_NOT_DIVIDE
	fi
	
	# remove this
	#CURRENT_FLAG=$IS_DIVIDE
}

# actions to take if IS_NOT_DIVIDE
commit_subnet () {
	commit_current_subnet
	# don't update child sum here.
	# instead do it inside update_INDEX
	#update_child_sum
}
update_current_item_index__ () {
	local _current_item_index=$(get_current_item_index)
	_current_item_index=$((_current_item_index+1))
	set_current_item_index $_current_item_index	
}

# test
#commit_subnet_and_update_child_sum
# look
#echo "$VLSM_MAP"
#echo "$OCCUPIED_SUBNETS"

# must remove this call after testing!!!!
#CURRENT_FLAG=$IS_FULL

########################
# BLOCK tests (non-MAIN)
########################
create_BLOCK () {
	# set block parent id of the new block to block id of the current block.
	# set block id of the new block to subnet[current_index].
	local block_parent_id=$(get_current_block_id)
	local current_index_of_subnet=$(get_current_index_of_current_block)
	local block_id=$(get_subnet_of_index $(get_current_block_id) $current_index_of_subnet)

	# test
	#echo new block parent id $block_parent_id
	#echo new block id $block_id

	# update current block id to this one.
	set_current_block_id "$block_id"

	# now fill in (block,child)(cidr|size)
	# calculate with one function call
	calculate_block_and_child_cidr_and_size
		
	# skeleton block json object to add to VLSM MAP.
	local new_block_skeleton=$(cat << EOF
{
	"block_id": "$block_id",
	"block_parent_id": "$block_parent_id",
	"current_index": 0,
	"child_sum": 0,
	"block_cidr": "",
	"block_size": "",
	"child_cidr": "",
	"child_size": "",
	"subnets": []
}
EOF
	)
	
	# now try to add the skeleton to VLSM MAP. done!
	VLSM_MAP=$(jq --argjson ITEM "$new_block_skeleton" '.+=[$ITEM]' <<< "$VLSM_MAP")
	
	# fill in fields...
	VLSM_MAP=$(jq --arg BLOCK_ID "$block_id" --arg BLOCK_CIDR "$block_cidr" '[.[] | select(.block_id==$BLOCK_ID).block_cidr=$BLOCK_CIDR]' <<< "$VLSM_MAP")
	VLSM_MAP=$(jq --arg BLOCK_ID "$block_id" --arg BLOCK_SIZE "$block_size" '[.[] | select(.block_id==$BLOCK_ID).block_size=$BLOCK_SIZE]' <<< "$VLSM_MAP")
	VLSM_MAP=$(jq --arg BLOCK_ID "$block_id" --arg CHILD_CIDR "$child_cidr" '[.[] | select(.block_id==$BLOCK_ID).child_cidr=$CHILD_CIDR]' <<< "$VLSM_MAP")
	VLSM_MAP=$(jq --arg BLOCK_ID "$block_id" --arg CHILD_SIZE "$child_size" '[.[] | select(.block_id==$BLOCK_ID).child_size=$CHILD_SIZE]' <<< "$VLSM_MAP")
	
	# map subnets of current block
	set_parameters_for_mapping
	map_network_with_subnets $CURRENT_BLOCK_CIDR $CURRENT_ITEM_SIZE $CURRENT_BLOCK_NET_ADDR
		
	# commit first subnet
	commit_first_subnet	
		
	# test	
	#echo "$VLSM_MAP"
	#echo "$TRACKER"
	#echo "$OCCUPIED_SUBNETS"

	# CREATED BLOCK
	CURRENT_FLAG=$CREATED_BLOCK
}
# test -- remove this!
#create_BLOCK

check_BLOCK_FULL () {

	#echo ***visiting check_BLOCK_FULL***

	local _current_block_id=$(get_current_block_id)
	local _block_size=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.block_size)"' <<< "$VLSM_MAP")
	local _child_sum=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.child_sum)"' <<< "$VLSM_MAP")
	
	# test
	#echo block size "$_block_size"
	#echo child sum "$_child_sum"

	#echo ***inside check_BLOCK_FULL block size "$_block_size" and child sum "$_child_sum"***
	
	if [ $_block_size -eq $_child_sum ] 
	then
		CURRENT_FLAG=$IS_BLOCK_FULL
	else
		CURRENT_FLAG=$IS_BLOCK_NOT_FULL
	fi

	#echo ***CURRENT_FLAG after check_BLOCK_FULL "$CURRENT_FLAG"

	#CURRENT_FLAG=$IS_BLOCK_FULL
}

update_BLOCK_INDEX () {
	# update child sum here instead of inside if IS_BLOCK_NOT_DIVIDE
	update_child_sum

	local _current_item_index=$(get_current_item_index)
	local _current_index=$(get_current_index_of_current_block)
	
	# increment current item index and current index by one.
	#_current_item_index=$((_current_item_index+1))	# not here!!!
	_current_index=$((_current_index+1))

	# test
	#echo updated current item index $_current_item_index
	#echo updated current index of current block $_current_index
	
	# qualifier
	local _total_number_of_items=${#required_items[@]}
	#echo total number of items $_total_number_of_items
	if [ $_current_item_index -le $((_total_number_of_items-1)) ]
	then
		#set_current_item_index $_current_item_index	# not here!
		set_current_index_of_current_block $_current_index
		CURRENT_FLAG=$IF_BLOCK_ITEM
	else
		CURRENT_FLAG=$IF_BLOCK_NO_ITEM
	fi
	#CURRENT_FLAG=$IF_BLOCK_ITEM
        #[ $commit_count_limit -eq 5 ] && CURRENT_FLAG=$IF_BLOCK_NO_ITEM
}

check_BLOCK_DIVIDE () {
	#echo ***visited check_BLOCK_DIVIDE***

	local _current_block_id=$(get_current_block_id)
	local _child_size_of_current_block=$(jq -r --arg BLOCK_ID "$_current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.child_size)"' <<< "$VLSM_MAP")
	
	# test
	#echo child size of current block $_child_size_of_current_block
	
	local _current_item_index=$(get_current_item_index)
	local _current_item=${required_items[$_current_item_index]}
	
	#test
	#echo current item index $_current_item_index
	#echo current_item $_current_item

	#echo ***child size is "$_child_size_of_current_block"***
	#echo ***current item is "$_current_item"***
	
	if [ $_child_size_of_current_block -gt $_current_item ]
	then
		CURRENT_FLAG=$IS_BLOCK_DIVIDE
	else
		CURRENT_FLAG=$IS_BLOCK_NOT_DIVIDE
	fi
	#CURRENT_FLAG=$IS_BLOCK_NOT_DIVIDE
}

up_to_PARENT () {
	# update current block id to that of PARENT block
	local current_block_id=$(get_current_block_id)
	local parent_block_id=$(jq -r --arg BLOCK_ID "$current_block_id" '.[] | select(.block_id==$BLOCK_ID) | "\(.block_parent_id)"' <<< "$VLSM_MAP")
	set_current_block_id "$parent_block_id"
	
	#echo ***visited up_to_PARENT***
	#echo ***current block id set to parent block id "$(get_current_block_id)"***
	
	# if PARENT is MAIN/ if PARENT is NOT MAIN
	if [ "$(get_current_block_id)" = "$starting_network" ]
	then
		CURRENT_FLAG=$PARENT_IS_MAIN
	else
		CURRENT_FLAG=$PARENT_IS_NOT_MAIN
	fi
	
	#echo ***inside up_to_PARENT CURRENT_FLAG is "$CURRENT_FLAG"***
	
	#CURRENT_FLAG=$PARENT_IS_MAIN
}

#echo current flag $CURRENT_FLAG

# qualifier for action while loop
is_there_item () {
	local _current_item_index=$(get_current_item_index)
	local _total_number_of_items=${#required_items[@]}
	
	test $_current_item_index -le $((_total_number_of_items-1))
}

###########
# the seed
###########
check_FULL
#create_BLOCK

# actions loop
while is_there_item 
do
	if [ $CURRENT_FLAG -eq $IS_FULL ]; then
		# here is a place to quit script if host size
		# user provided is too large!
		#echo full!
		echo "Error: host size you've provided is too large"
		echo
		exit_abnormal		
		break
	fi

	if [ $CURRENT_FLAG -eq $IS_NOT_FULL ]; then
		update_INDEX
	fi

	if [ $CURRENT_FLAG -eq $IF_NO_ITEM ]; then
		#echo no more!
		break
	fi

	if [ $CURRENT_FLAG -eq $IF_ITEM ]; then
		check_DIVIDE
	fi

	if [ $CURRENT_FLAG -eq $IS_NOT_DIVIDE ]; then
		#commit_count_limit=$((commit_count_limit+1))
		commit_subnet
		update_current_item_index__
		#echo commit from main!
		check_FULL
	fi

        if [ $CURRENT_FLAG -eq $IS_DIVIDE ]; then
		create_BLOCK
        fi

        if [ $CURRENT_FLAG -eq $CREATED_BLOCK ]; then
                check_BLOCK_FULL
        fi

        if [ $CURRENT_FLAG -eq $IS_BLOCK_FULL ]; then
		up_to_PARENT
        fi

        if [ $CURRENT_FLAG -eq $IS_BLOCK_NOT_FULL ]; then
                update_BLOCK_INDEX
        fi

        if [ $CURRENT_FLAG -eq $IF_BLOCK_ITEM ]; then
                check_BLOCK_DIVIDE
        fi

        if [ $CURRENT_FLAG -eq $IF_BLOCK_NO_ITEM ]; then
                #echo no more!
                break
        fi

        if [ $CURRENT_FLAG -eq $IS_BLOCK_DIVIDE ]; then
		 #echo ***visited IS_BLOCK_DIVIDE***
                create_BLOCK
        fi

        if [ $CURRENT_FLAG -eq $IS_BLOCK_NOT_DIVIDE ]; then
                #commit_count_limit=$((commit_count_limit+1))
                commit_subnet
                update_current_item_index__
                #echo commit!
                check_BLOCK_FULL
        fi

        if [ $CURRENT_FLAG -eq $PARENT_IS_MAIN ]; then
                check_FULL
        fi

        if [ $CURRENT_FLAG -eq $PARENT_IS_NOT_MAIN ]; then
                check_BLOCK_FULL
        fi
done

#############
# view result
#############
echo
echo starting network
echo "$starting_network"
echo
#echo required items
#echo "${required_items[@]}"
#echo
#echo vlsm map:
#echo "$VLSM_MAP"
#echo tracker
#echo "$TRACKER"
#echo occupied subnets
#echo "$OCCUPIED_SUBNETS"

###########################################
# print occupied subnets' id, name and size
###########################################
LIST_END_SUBNETS_NAMES=($(jq -r '.[]|.name' <<< "$OCCUPIED_SUBNETS" | tr '\n' ' '))
#echo "${LIST_END_SUBNETS_NAMES[@]}"

for (( i=0; i<${#LIST_START_IDS[@]}; i++ ))
do
	#echo "${LIST_START_IDS[$i]}": "${LIST_END_SUBNETS_NAMES[$i]}"	# print 'id: name' per occupied subnet
	# try fixed column sizes
	printf '%-20s: %-20s: %-15s\n' "${LIST_START_IDS[$i]}" "${LIST_END_SUBNETS_NAMES[$i]}" "${LIST_START_SIZES[$i]} hosts"
done

