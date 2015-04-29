jurmous/hadoop is Hadoop distributed storage engine packaged in lightweight docker and configured in a way to easily run it distributed with High Availability.

# Package details
* Java 7 (The latest from java:7 as base container)
* Hadoop 2.6.0
* Bash
* No extra packaged OS to be lighter.

# TODO
* Add automatic failover with Zookeeper.

# How to run
To run the container you have to give it a few variables. You start/schedule some separate containers for each needed hadoop service. 

Needed services for a cluster:

* 3 or more uneven amount of JournalNodes
* 2 NameNodes
* At least 3 DataNodes

It is probably wise to do all setup with a scheduler and some helpers to obtain the addresses of the Nodes as they come online. You could use Fleet or Kubernetes for this. Make sure the namenodes are at least always attached to the same storage for persistence.

Run example to start the namenode:
``` docker run -it -e "NNODE1_IP=nn1" -e "NNODE2_IP=nn2" -e "JN_IPS=j1,j2,j3" -v $NAMENODE_FOLDER_ON_HOST:/mnt/hadoop/dfs/name jurmous/hadoop /etc/bootstrap.sh -d namenode ```

The bootstrap is needed to setup all the configuration.
The parameters after /etc/bootstrap.sh  are given to ```hadoop-daemon.sh start```.  There are some extra parameters like -d described in next section.
## Extra bootstrap parameters
* ```-d``` - Runs the service continuously instead of auto quiting
* ```-b``` - Opens a bash terminal after starting to inspect its internal file system.

## Cluster name
By default the cluster will start with the name "cluster". You can set this name with ```$CLUSTER_NAME```

## Mandatory environment variables
For the containers to run you need to set 3 environment variable on the docker run command.

* ```NNODE1_IP``` : Address to NameNode 1.
* ```NNODE2_IP``` : Address to NameNode 2.
* ```JN_IPS```: Comma separated addresses for JournalNodes. (At least 3 or more as long as it is an uneven number.)

Example part to set environment variables. Add this to the docker run command:
``` -e "NNODE1_IP=nn1.example.com" -e "NNODE2_IP=nn2.example.com" -e "JN_IPS=jn1.example.com,jn2.example.com,jn3.example.com"```

## Storage
Link folders to the following folders for permanent storage:

* ```/mnt/hadoop/dfs/name``` - For NameNode storage
* ```/mnt/hadoop/dfs/data``` - For DataNode storage
* ```/mnt/hadoop/journal/data``` - For Journal storage
* ```/usr/local/hadoop/logs/``` - For the logs. You can also replace the ```/usr/local/hadoop/etc/log4j.properties``` with an attach docker volume to that file to customize the logging settings

Example to link storage for the NameNode:
``` -v $NAMENODE_FOLDER_ON_HOST:/mnt/hadoop/dfs/name```

# Formatting HDFS
For first time use it is needed to format HDFS by formatting the NameNode and sync the second namenode. It is needed to start all the journalnodes and both namenodes in docker with the correct volume and environment settings. Then you can use bash to get into the namenodes to do the formatting.

## NameNode 1
* Named hadoop-nn1 in this example. Create a bash prompt: ```docker exec -it hadoop-nn1 bash```
* Run the format command. ```$HADOOP_PREFIX/bin/hdfs namenode -format```
* Kill and start NameNode1 container again.

## NameNode 2
* Named hadoop-nn2 in this example. Create a bash prompt: ```docker exec -it hadoop-nn2 bash```
* Run the format command. ```$HADOOP_PREFIX/bin/hdfs namenode -bootstrapStandby```
* Kill and start NameNode2 container again.

# Fencing
In certain situations the NameNodes need to fence for a proper failover. Now the Fence will always return true without doing anything. Replace ```/etc/fence.sh`` with a docker volume attach for your own fencing algorithm. Probably something like a call to your docker scheduler to close down the other NameNode.

# Other resources
* [Hadoop HA with JournalNode Quorum](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html)