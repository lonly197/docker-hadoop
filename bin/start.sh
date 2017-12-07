#!/bin/bash

set -eo pipefail
exec su-exec hdfs hdfs --config "${HADOOP_CONF_DIR}" namenode -format -nonInteractive
exec su-exec hdfs ${HADOOP_HOME}/sbin/start-dfs.sh
exec su-exec yarn ${HADOOP_HOME}/sbin/start-yarn.sh