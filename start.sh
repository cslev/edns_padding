#!/bin/bash
 
 ROOT="$(dirname "$0")"
 source $ROOT/sources/extra.sh
 
 
function show_help 
 { 
 	c_print "Green" "This script tests public DoH resolvers and their compliance with EDNS padding. More precisely, it sends query to them using DoH, and saves the corresponding communication in pcap files for further analysis..."
 	c_print "Bold" "Example: sudo ./start.sh -r doh_resolvers.json -i eth0"
 	c_print "Bold" "\t-r <RESOLVER_JSON>: the json file containing resolver information (Default: doh_resolvers.json)."
  c_print "Bold" "\t-i <IFACE>: interface to listen to via tcpdump (Default: eth0)."

 	exit
 }

RESOLVER_JSON=""
IFACE=""

while getopts "h?r:i:" opt
do
 	case "$opt" in
 	h|\?)
 		show_help
 		;;
 	r)
 	  RESOLVER_JSON=$OPTARG
 		;;
  i)
    IFACE=$OPTARG
    ;;
 	*)
 		show_help
 		;;
 	esac
done


if [ -z $RESOLVER_JSON ]
then
  c_print "Yellow" "RESOLVER_JSON is not set, fallback to default: doh_resolvers.json"
  RESOLVER_JSON=doh_resolvers.json
fi

if [ -z $IFACE ]
then
  c_print "Yellow" "Interface to listen to is not set...fallback to default: doh_resolvers.json"
  IFACE="eth0"
fi

c_print "White" "Checking if run as root..." 1
ROOT_USER=$(id |grep root > /dev/null)
retval=$(echo $?)
check_retval $retval

c_print "White" "Checking if you have JSON parsing library 'jq'..." 1
which jq > /dev/null
retval=$?
check_retval $retval

for i in $(jq ".[].simple_name" $RESOLVER_JSON )
do
  c_print "White" "${i}...(sleeping 2 sec)"
  sleep 2s

  simple_name=$(echo $i|sed "s/\"//g")
  uri=$(jq .${i}.uri $RESOLVER_JSON | sed "s/\"//g")
  ip=$(jq .${i}.bootstrap $RESOLVER_JSON | sed "s/\"//g") 
 
  c_print "White" "starting tcpdump in the background..."
  tcpdump -ni $IFACE -w $simple_name.pcap > /dev/null &  
  pid=$(echo $!)
  c_print "White" "PID of tcpdump is: ${pid}"

  c_print "White" "testing resolver ${uri}"
  c_print "White" "known bootstrap IP: ${ip}"

  c_print "White" "-----------------------------------------------------------------------"
  c_print "White" "Testing with 2 different domains with different lengths to see size difference in query/response "
  kdig @${ip} +tls +https=${uri} +edns google.com
  kdig @${ip} +tls +https=${uri} +edns facebook.com
  
  c_print "White" "-----------------------------------------------------------------------"
  c_print "White" "Testing with the same domain 5 times to see if hitting a different backend server or checking if random padding is applied"
  for j in {1..5}
  do
    kdig @${ip} +tls +https=${uri} +edns google.com
    sleep 2s
  done
  
  c_print "White" "Killing tcpdump..."
  kill -9 $pid
  retval=$(echo $?)
  check_retval $retval


done



