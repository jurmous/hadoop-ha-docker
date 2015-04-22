#!/bin/bash

checkArg () {
  s=0

  if [[ $1 == "-d" ]]; then
    keeprunning=true
    shift 1
    let "s++"
  fi
  
  if [[ $1 == "-b" ]]; then
    bash=true
    shift 1
    let "s++"
  fi
  
  shift=$s
}

: ${HADOOP_PREFIX:=/usr/local/hadoop};

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

checkArg $@
shift $shift

server="datanode"
if [[ -z $1 ]]; then
  # continue on with server as datanode 
  echo Will start a DataNode
else
  server=$1
  shift 1
fi

if [[ $server = "namenode" ]]; then
  sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
fi

echo $HADOOP_PREFIX/sbin/hadoop-daemon.sh start $server $@

$HADOOP_PREFIX/sbin/hadoop-daemon.sh start $server $@

if [[ $keeprunning = true ]]; then
  while true; do sleep 1000; done
fi

if [[ $bash = true ]]; then
  /bin/bash
fi