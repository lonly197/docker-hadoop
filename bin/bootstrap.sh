#!/bin/bash

set -eo pipefail
exec su-exec hadoop ${HADOOP_CONF_DIR}/hadoop-env.sh
exec su-exec hdfs hdfs --config "${HADOOP_CONF_DIR}" namenode -format -nonInteractive
exec su-exec hdfs ${HADOOP_HOME}/sbin/start-dfs.sh
exec su-exec yarn ${HADOOP_HOME}/sbin/start-yarn.sh

set +e -x
su-exec hdfs hdfs dfs -mkdir -p /tmp
su-exec hdfs hdfs dfs -chmod 1777 /tmp
su-exec hdfs hdfs dfs -mkdir -p /user/hdfs
su-exec hdfs hdfs dfs -chmod 755 /user