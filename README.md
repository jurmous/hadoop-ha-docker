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
``` docker run -it -e "NNODE1_IP=nn1" -e "NNODE2_IP=nn2" -e "JN_IPS=j1,j2,j3" -v $NAMENODE_FOLDER_ON_HOST:/home/hadoop/dfs/name jurmous/hadoop /etc/bootstrap.sh -d namenode ```

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

* ```/home/hadoop/dfs/name``` - For NameNode storage
* ```/home/hadoop/dfs/data``` - For DataNode storage
* ```/home/hadoop/journal/data``` - For Journal storage
* ```/usr/local/hadoop/logs/``` - For the logs. You can also replace the ```/usr/local/hadoop/etc/log4j.properties``` with an attach docker volume to that file to customize the logging settings

Example to link storage for the NameNode:
``` -v $NAMENODE_FOLDER_ON_HOST:/home/hadoop/dfs/name```

# Formatting HDFS
For first time use it is needed to format the NameNode and you can start it with the ```format``` keyword. In HA mode it is needed to supply the addresses of the quorum and the NameNodes. You need to run docker with the -it command to see the "Are you sure" question. This can be done with the following command on the machines that host the NameNode:

Example:
```docker run -it -e "NNODE1_IP=$NNODE1_IP" -e "NNODE2_IP=$NNODE2_IP" -e "JN_IPS=jn1,jn2,jn3" -v /home/core/hadoop/logs/:/usr/local/hadoop/logs/ -v  $NAMENODE_FOLDER_ON_HOST:/home/hadoop/dfs/name jurmous/hadoop /etc/bootstrap.sh format```

# Fencing
In certain situations the NameNodes need to fence for a proper failover. Now the Fence will always return true without doing anything. Replace ```/etc/fence.sh`` with a docker volume attach for your own fencing algorithm. Probably something like a call to your docker scheduler to close down the other NameNode.

# Other resources
* [Hadoop HA with JournalNode Quorum](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html)