# Hadoop image
FROM java:7
MAINTAINER jurmous

RUN curl -s http://www.eu.apache.org/dist/hadoop/common/hadoop-2.5.2/hadoop-2.5.2.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./hadoop-2.5.2 hadoop

RUN apt-get update \
  && apt-get install bash \
  && apt-get install jq

ENV USER root
ENV JAVA_HOME /usr/lib/jvm/java-1.7.0-openjdk-amd64

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

WORKDIR /usr/local/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh

RUN mkdir -p /mnt/hadoop/dfs/name && mkdir -p /mnt/hadoop/dfs/data && mkdir -p /mnt/hadoop/journal/data

ADD core-site.xml.template /usr/local/hadoop/etc/hadoop/core-site.xml.template
ADD hdfs-site.xml.template /usr/local/hadoop/etc/hadoop/hdfs-site.xml.template

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && chmod a+x /etc/bootstrap.sh

ADD fence.sh /etc/fence.sh
RUN chown root:root /etc/fence.sh && chmod a+x /etc/fence.sh

CMD ["/etc/bootstrap.sh", "-d"]

# NameNode                Secondary NameNode  DataNode                     JournalNode  NFS Gateway    HttpFS         ZKFC
EXPOSE 8020 50070 50470   50090 50495         50010 1004 50075 1006 50020  8485 8480    2049 4242 111  14000 14001    8019