jurmous/hadoop is Hadoop distributed storage engine packaged in lightweight docker and configured in a way to easily run it distributed with High Availability.

# Package details
* Java 7 (The latest from java:7 as base container)
* Hadoop 2.5.1
* Bash
* No extra packaged OS to be lighter.

# How to run
To run the container you have to give it a few variables. You start/schedule some separate containers for each needed hadoop service.  If a service stops the container will close automatically.

Needed services for a cluster:

* At least 3 Zookeepers or a bigger uneven amount of zookeepers. (jurmous/zookeeper can be used) for automatic failover.

* 3 or more uneven amount of JournalNodes
* 2 NameNodes (The Zookeeper Failover Controller runs automatically inside)
* At least 3 DataNodes

It is probably wise to do all setup with a scheduler and some helpers to obtain the addresses of the Nodes as they come online. You could use Fleet or Kubernetes for this. Make sure the namenodes are at least always attached to the same storage for persistence.

Run example to start the namenode:
``` docker run -it -e "NNODE1_IP=nn1" -e "NNODE2_IP=nn2" -e "JN_IPS=j1:8485,j2:8485,j3:8485" -e "ZK_IPS=zk1:2181,zk2:2181,zk3:2181"  -v $NAMENODE_FOLDER_ON_HOST:/mnt/hadoop/dfs/name jurmous/hadoop /etc/bootstrap.sh -d namenode ```

The bootstrap is needed to setup all the configuration.
The parameters after /etc/bootstrap.sh  are given to ```hadoop-daemon.sh start```.  There are some extra parameters like -d described in next section.

## Extra bootstrap parameters
* ```-d``` - Runs the service continuously instead of auto quiting
* ```-b``` - Opens a bash terminal after starting to inspect its internal file system.

## Cluster name
By default the cluster will start with the name "cluster". You can set this name with ```$CLUSTER_NAME```

## Mandatory environment variables
For the containers to run you need to set 3 environment variable on the docker run command.

* ```NNODE1_IP``` : Address to NameNode 1 without port
* ```NNODE2_IP``` : Address to NameNode 2 without port
* ```JN_IPS```: Comma separated addresses for JournalNodes with port 8485. (At least 3 or more as long as it is an uneven number.)
* ```ZK_IPS```: Comma separated addresses for Zookeeper nodes with port (default is 2181).  (At least 3 or more as long as it is an uneven number.)

Example part to set environment variables. Add this to the docker run command:
``` -e "NNODE1_IP=nn1.example.com" -e "NNODE2_IP=nn2.example.com" -e "JN_IPS=jn1.example.com:8485,jn2.example.com:8485,jn3.example.com:8485" e "ZK_IPS=zk1.example.com:2181,zk2.example.com:2181,zk3.example.com:2181"```

## Storage
Link folders to the following folders for permanent storage:

* ```/mnt/hadoop/dfs/name``` - For NameNode storage
* ```/mnt/hadoop/dfs/data``` - For DataNode storage
* ```/mnt/hadoop/journal/data``` - For Journal storage
* ```/usr/local/hadoop/logs/``` - For the logs. You can also replace the ```/usr/local/hadoop/etc/log4j.properties``` with an attach docker volume to that file to customize the logging settings

Example to link storage for the NameNode:
``` -v $NAMENODE_FOLDER_ON_HOST:/mnt/hadoop/dfs/name```

## Networking

It is important that the IPs of the namenode are the IP address/DNS name of the containers because Hadoop actually binds to those addresses.

The easy way is to attach the host network interfaces to the container with ```--net="host"``` in the docker run command.

It is also possible to use flannel to route the traffic directly to the containers but you then need to take care of the IP announcements so each container knows which ones it needs to connect to.

# Formatting HDFS
For first time use it is needed to format HDFS by formatting the NameNode and sync the second namenode. It is needed to start all the journalnodes and to know the IPs of the machines the namenode is going to be run on. 

## NameNode 1
Run docker image with -it flag for interactive input and run it with format command. It is important to attach your permanent storage volume!
```docker run -it -p 50470:50470 -p 8020:8020 -p 50070:50070 -e NNODE1_IP=$NNODE1IP -e NNODE2_IP=$NNODE2IP -e JN_IPS=$JNIPS -e ZK_IPS=$ZKIPS -v $NAMENODE_FOLDER_ON_HOST:/mnt/hadoop/dfs/name jurmous/hadoop:2.5 /etc/bootstrap.sh -d format```

## NameNode 2
The second namenode needs to be bootstrapped with the formatting of the first namenode. To do this you need to run the bootstrap command in interactive mode while namenode 1 is running. It is important to attach your permanent storage volume!
```docker run -it  -p 50470:50470 -p 8020:8020 -p 50070:50070 -e NNODE1_IP=$NNODE1IP -e NNODE2_IP=$NNODE2IP -e JN_IPS=$JNIPS -e ZK_IPS=$ZKIPS -v $NAMENODE_FOLDER_ON_HOST:/mnt/hadoop/dfs/name jurmous/hadoop:2.5 /etc/bootstrap.sh -d format```

# Fencing
In certain situations the NameNodes need to fence for a proper failover. Now the Fence will always return true without doing anything. Replace ```/etc/fence.sh`` with a docker volume attach for your own fencing algorithm. Probably something like a call to your docker scheduler to close down the other NameNode.

# Other resources
* [Hadoop HA with JournalNode Quorum](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html)