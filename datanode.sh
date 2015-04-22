#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

test=0;

while [ $test -ne -1 ]; do
    curl -sf http://$DOCKERHOST:4001/v2/keys/hadoop/namenode/ip
    if [ $? -eq 0 ]; then
      namenode=$(curl -sf http://$DOCKERHOST:4001/v2/keys/hadoop/namenode/ip | sed -n -e 's/.*"value":"\([^"]*\)".*/\1/p')
      test=-1;
    else  
      echo again $test;
      let "test+=1";
      sleep 2;
    fi;
done


# altering the core-site configuration
sed s/HOSTNAME/$namenode/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml

service sshd start
$HADOOP_PREFIX/sbin/hadoop-daemon.sh start datanode

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
