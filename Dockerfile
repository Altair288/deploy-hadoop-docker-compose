# syntax=docker/dockerfile:1

# 参考资料: https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html

FROM ubuntu:20.04

ARG TARBALL=hadoop-3.4.1.tar.gz
# 提前下载好的java8压缩包, 下载地址: https://www.oracle.com/java/technologies/downloads/
ARG JAVA_TARBALL=jdk-8u212-linux-x64.tar.gz

ENV HADOOP_HOME /app/hadoop
ENV JAVA_HOME /usr/java

WORKDIR $JAVA_HOME
WORKDIR $HADOOP_HOME

RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    apt-get clean && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    wget \
    ssh

# 拷贝jdk8安装包
COPY ${JAVA_TARBALL} ${JAVA_HOME}/${JAVA_TARBALL}

RUN tar -zxvf /usr/java/${JAVA_TARBALL} --strip-components 1 -C /usr/java && \
    rm /usr/java/${JAVA_TARBALL} && \
    # 设置java8环境变量
    echo export JAVA_HOME=${JAVA_HOME} >> ~/.bashrc && \
    echo export PATH=\$PATH:\$JAVA_HOME/bin >> ~/.bashrc && \
    echo export JAVA_HOME=${JAVA_HOME} >> /etc/profile && \
    echo export PATH=\$PATH:\$JAVA_HOME/bin >> /etc/profile && \
    # 下载hadoop安装包
    wget --no-check-certificate https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/stable/${TARBALL} && \
    # 解压hadoop安装包
    tar -zxvf ${TARBALL} --strip-components 1 -C $HADOOP_HOME && \
    rm ${TARBALL} && \
    # 设置从节点
    echo "worker1\nworker2\nworker3" > $HADOOP_HOME/etc/hadoop/workers && \
    echo export HADOOP_HOME=${HADOOP_HOME} >> ~/.bashrc && \
	echo export PATH=\$PATH:\$HADOOP_HOME/bin >> ~/.bashrc && \
	echo export PATH=\$PATH:\$HADOOP_HOME/sbin >> ~/.bashrc && \
	echo export HADOOP_HOME=${HADOOP_HOME} >> /etc/profile && \
	echo export PATH=\$PATH:\$HADOOP_HOME/bin >> /etc/profile && \
	echo export PATH=\$PATH:\$HADOOP_HOME/sbin >> /etc/profile && \
    mkdir /app/hdfs && \
    # java8软连接
    ln -s $JAVA_HOME/bin/java /bin/java

# 拷贝hadoop配置文件
COPY hadoop/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY hadoop/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY hadoop/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY hadoop/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml

# 设置hadoop环境变量
RUN echo export JAVA_HOME=$JAVA_HOME >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HADOOP_MAPRED_HOME=$HADOOP_HOME >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HDFS_NAMENODE_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HDFS_DATANODE_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HDFS_SECONDARYNAMENODE_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export YARN_RESOURCEMANAGER_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export YARN_NODEMANAGER_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
# ssh免登录设置
RUN echo "/etc/init.d/ssh start" >> ~/.bashrc && \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

EXPOSE 8088
EXPOSE 8030
EXPOSE 8031
# NameNode WEB UI服务端口
EXPOSE 9870
# nn文件服务端口
EXPOSE 9000
# dfs.namenode.secondary.http-address
EXPOSE 9868
# dfs.datanode.http.address
EXPOSE 9864
# dfs.datanode.address
EXPOSE 9866
