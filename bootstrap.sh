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

if [ -z $CLUSTER_NAME ]; then
  CLUSTER_NAME="cluster"
  export CLUSTER_NAME
fi

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

if [ -z $NNODE1_IP ] || [ -z $NNODE2_IP ] || [ -z $JN_IPS ]; then
  echo NNODE1_IP, NNODE2_IP and JN_IPS needs to be set as environment addresses to be able to run.
  exit;
fi

if [[ $NNODE1_IP = "localhost" ]]; then
  NNODE1_IP=$HOSTNAME
fi

if [[ $NNODE2_IP = "localhost" ]]; then
  NNODE2_IP=$HOSTNAME
fi

arr=$(echo $JN_IPS | tr "," "\n")
JNODES=""
for x in $arr
do
    if [ "$JNODES" != "" ]; then
      JNODES+=";"
    fi
    JNODES+="$x:8485"
done

sed "s/CLUSTER_NAME/$CLUSTER_NAME/" /usr/local/hadoop/etc/hadoop/hdfs-site.xml.template \
| sed "s/NNODE1_IP/$NNODE1_IP/" \
| sed "s/NNODE2_IP/$NNODE2_IP/" \
| sed "s/JNODES/$JNODES/" \
> /usr/local/hadoop/etc/hadoop/hdfs-site.xml

echo CLUSTER_NAME=$CLUSTER_NAME NNODE1_IP=$NNODE1_IP NNODE2_IP=$NNODE2_IP JNODES=$JNODES

sed "s/CLUSTER_NAME/$CLUSTER_NAME/" /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml

if [[ $server = "format" ]]; then
  read -p "Are you sure to format the hdfs volume? " -n 1 -r
  echo  
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    $HADOOP_PREFIX/bin/hadoop namenode -format
    exit;
  fi
  exit;
fi

echo $HADOOP_PREFIX/sbin/hadoop-daemon.sh start $server $@

$HADOOP_PREFIX/sbin/hadoop-daemon.sh start $server $@

if [[ $keeprunning = true ]]; then
  while true; do sleep 1000; done
fi

if [[ $bash = true ]]; then
  /bin/bash
fi