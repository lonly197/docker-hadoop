FROM lonly/docker-hadoop:hadoop2-env

ARG VERSION=2.9.0-base
ARG BUILD_DATE
ARG VCS_REF

LABEL \
    maintainer="lonly197@qq.com" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="lonly/docker-hadoop" \
    org.label-schema.url="https://github.com/lonly197" \
    org.label-schema.description="Hadoop(Common/HDFS/YARN/MapReduce) docker image based on alpine." \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/lonly197/docker-hadoop" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vendor="lonly197@qq.com" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

# Define environment
ENV HADOOP_VERSION=${VERSION} \
    HADOOP_HOME=/usr/local/hadoop \
    HADOOP_COMMON_HOME=${HADOOP_HOME} \
    HADOOP_HDFS_HOME=${HADOOP_HOME} \
    HADOOP_MAPRED_HOME=${HADOOP_HOME} \
    HADOOP_YARN_HOME=${HADOOP_HOME} \
    HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop \
    HADOOP_LOG_DIR=/var/log/hdfs \
    HADOOP_TMP_DIR=/hadoop \
    YARN_CONF_DIR=${HADOOP_HOME}/etc/hadoop \
    YARN_HOME=${HADOOP_HOME} \
    YARN_LOG_DIR=/var/log/yarn \
    PTAH=$PTAH:${HADOOP_HOME}:${HADOOP_HOME}/bin

# Install Hadoop
RUN set -x \
    ## Install dependency lib 
    && apk add --no-cache --upgrade --virtual=build-dependencies su-exec gnupg openssl ca-certificates \
    && update-ca-certificates \
    ## Download hadoop bin
    && mirror_url=$( \
        wget -q -O - "http://www.apache.org/dyn/closer.cgi/?as_json=1" \
        | grep "preferred" \
        | sed -n 's#.*"\(http://*[^"]*\)".*#\1#p' \
        ) \
    && wget ${mirror_url}hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    ## Unzip tar
    && tar -xzvf hadoop-${HADOOP_VERSION}.tar.gz -C /tmp \
    ## Install hadoop bin
    && mv /tmp/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    ## Clean
    && apk del build-dependencies \
    && rm -rf ${HADOOP_HOME}/share/doc \
    && for dir in common hdfs mapreduce tools yarn; do \
         rm -rf ${HADOOP_HOME}/share/hadoop/${dir}/sources; \
       done \
    && rm -rf ${HADOOP_HOME}/share/hadoop/common/jdiff \
    && rm -rf ${HADOOP_HOME}/share/hadoop/mapreduce/lib-examples \
    && rm -rf ${HADOOP_HOME}/share/hadoop/yarn/test \
    && find ${HADOOP_HOME}/share/hadoop -name *test*.jar | xargs rm -rf \
    && rm -rf /root/.cache \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Set Environment
RUN set -x \
    ## Install base package
    && apk add --no-cache --upgrade su-exec \
    ## Add profile
    && env \
       | grep -E '^(JAVA|HADOOP|PATH|YARN)' \
       | sed 's/^/export /g' \
       > ~/.profile \
    && cp ~/.profile /etc/profile.d/hadoop \
    && sed -i 's@${JAVA_HOME}@'${JAVA_HOME}'@g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh \
    ## Add user
    && adduser -D -g '' -s /sbin/nologin -u 1000 docker \
    && for user in hadoop hdfs yarn mapred hbase; do \
         adduser -D -g '' -s /sbin/nologin ${user}; \
       done \
    && for user in root hdfs yarn mapred hbase docker; do \
         adduser ${user} hadoop; \
       done \
    ## Mkdir dir
    && mkdir -p \
        ${HADOOP_TMP_DIR}/dfs \
        ${HADOOP_TMP_DIR}/yarn \
        ${HADOOP_TMP_DIR}/mapred \
        ${HADOOP_TMP_DIR}/nm-local-dir \
        ${HADOOP_TMP_DIR}/yarn-nm-recovery \
        ${HADOOP_LOG_DIR} \
        ${YARN_LOG_DIR} \
    ## Chmod user permission
    && chmod -R 775 \
        ${HADOOP_LOG_DIR} \
        ${YARN_LOG_DIR} \
    && chmod -R 700 ${HADOOP_TMP_DIR}/dfs \
    && chown -R hdfs:hadoop \
        ${HADOOP_TMP_DIR}/dfs \
        ${HADOOP_LOG_DIR} \
    && chown -R hadoop:hadoop \
        ${HADOOP_TMP_DIR}/dfs \
        ${HADOOP_LOG_DIR} \
    && chown -R yarn:hadoop \
        ${HADOOP_TMP_DIR}/yarn \
        ${HADOOP_TMP_DIR}/nm-local-dir \
        ${HADOOP_TMP_DIR}/yarn-nm-recovery \
        ${YARN_LOG_DIR} \
    && chown -R mapred:hadoop ${HADOOP_TMP_DIR}/mapred \
    ## Clean
    && rm -rf /root/.cache \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*