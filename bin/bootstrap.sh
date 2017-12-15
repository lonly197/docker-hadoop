#!/bin/sh

set -eo pipefail

wait_until() {
    local hostname=${1?}
    local port=${2?}
    local retry=${3:-100}
    local sleep_secs=${4:-2}
    
    local address_up=0
    
    while [ ${retry} -gt 0 ] ; do
        echo  "Waiting until ${hostname}:${port} is up ... with retry count: ${retry}"
        if nc -z ${hostname} ${port}; then
            address_up=1
            break
        fi        
        retry=$((retry-1))
        sleep ${sleep_secs}
    done 
    
    if [ $address_up -eq 0 ]; then
        echo "GIVE UP waiting until ${hostname}:${port} is up! "
        exit 1
    fi       
}

# apply template
chmod 750 /usr/local/bin/mustache.sh
for template in $(ls ${HADOOP_CONF_DIR}/*.mustache)
do
    conf_file=${template%.mustache}
    cat ${conf_file}.mustache | /usr/local/bin/mustache.sh > ${conf_file}
done

# start hadoop service
if  [ "$1" == "journalnode" ]; then
    exec su-exec hdfs hdfs journalnode
    
elif [ "$1" == "namenode" ]; then
    if [ ! -e "${HADOOP_TMP_DIR}/dfs/name/current/VERSION" ]; then
        su-exec hdfs hdfs namenode -format -force
    fi        
         
    exec su-exec hdfs hdfs namenode
    
elif [ "$1" == "datanode" ]; then
    wait_until "namenode" 8020 
    exec su-exec hdfs hdfs datanode
       
elif [ "$1" == "resourcemanager" ]; then
    exec su-exec yarn yarn resourcemanager

elif [ "$1" == "nodemanager" ]; then
    wait_until "resourcemanager" 8031
    exec su-exec yarn yarn nodemanager
    
elif [ "$1" == "historyserver" ]; then    
    wait_until "namenode"  8020 
    
    set +e -x
    
    su-exec hdfs hdfs dfs -ls /tmp > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        su-exec hdfs hdfs dfs -mkdir -p /tmp
        su-exec hdfs hdfs dfs -chmod 1777 /tmp
    fi
    
    su-exec hdfs hdfs dfs -ls /user > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        su-exec hdfs hdfs dfs -mkdir -p /user/hdfs
        su-exec hdfs hdfs dfs -chmod 755 /user
    fi
    
    su-exec hdfs hdfs dfs -ls ${YARN_REMOTE_APP_LOG_DIR} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        su-exec yarn hdfs dfs -mkdir -p ${YARN_REMOTE_APP_LOG_DIR}
        su-exec yarn hdfs dfs -chmod -R 1777 ${YARN_REMOTE_APP_LOG_DIR}
        su-exec yarn hdfs dfs -chown -R yarn:hadoop ${YARN_REMOTE_APP_LOG_DIR}
    fi
    
    su-exec hdfs hdfs dfs -ls ${YARN_APP_MAPRED_STAGING_DIR} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        su-exec mapred hdfs dfs -mkdir -p ${YARN_APP_MAPRED_STAGING_DIR}
        su-exec mapred hdfs dfs -chmod -R 1777 ${YARN_APP_MAPRED_STAGING_DIR}
        su-exec mapred hdfs dfs -chown -R mapred:hadoop ${YARN_APP_MAPRED_STAGING_DIR}
    fi
    
    set -e +x 
            
    exec su-exec mapred mapred historyserver

else

    exec su-exec hdfs ${HADOOP_HOME}/sbin/start-dfs.sh
    exec su-exec yarn ${HADOOP_HOME}/sbin/start-yarn.sh

    set +e -x

    su-exec hdfs hdfs dfs -mkdir -p /tmp
    su-exec hdfs hdfs dfs -chmod 1777 /tmp
    su-exec hdfs hdfs dfs -mkdir -p /user/hdfs
    su-exec hdfs hdfs dfs -chmod 755 /user
       
fi

exec "$@"