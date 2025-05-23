#!/bin/bash
# 启动 ZooKeeper
/usr/zookeeper/bin/zkServer.sh start

# 可选：启动 Hadoop 相关服务
# /app/hadoop/sbin/start-dfs.sh
# /app/hadoop/sbin/start-yarn.sh

# 启动 SSH 服务
service ssh start

# 添加 Hadoop 节点到 known_hosts
for host in hadoop330 master2 worker1 worker2 worker3; do
    ssh-keyscan -H $host >> ~/.ssh/known_hosts 2>/dev/null
done

# 保持容器前台运行
tail -f /dev/null