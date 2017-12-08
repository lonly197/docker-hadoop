FROM lonly/docker-alpine-java:oraclejre-8u152

ARG VERSION=2.9.0
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
    HADOOP_HOME=/usr/local/hadoop-${HADOOP_VERSION} \
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

# Install Base Package
RUN set -x \
    && apk add --no-cache --upgrade --virtual=build-dependencies \
        openssl \
        supervisor \
    ## Clean
    && apk del build-dependencies \
    && rm -rf /root/.cache \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Install SSH Key
RUN set -x \
    && apk add --no-cache --upgrade --virtual=build-dependencies openssh \
    ## Make sure we get fresh keys
    && rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key \
    && ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa \
    && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys \
    && chmod 0600 ~/.ssh/authorized_keys \
    ## Clean
    && apk del build-dependencies \
    && rm -rf /root/.cache \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Install Protobuf
RUN	set -x \
    ## Define Variant
    && PROTOBUF_VERSION=2.5.0 \
    && GOOGLETEST_VERSION=1.5.0 \
	## Update apk
	&& apk update \
    ## Install build protobuf package
    && apk add --no-cache --upgrade --virtual=build-dependencies \
            autoconf \
            automake \
            build-base \
            libtool \
            zlib-dev \
            ca-certificates \
            openssl \
    && update-ca-certificates \
    ## Download protobuf
    && wget -q -O - https://github.com/google/protobuf/archive/v${PROTOBUF_VERSION}.tar.gz \
        | tar -zxvf - -C /tmp \
    && cd /tmp/protobuf-* \
    ## Download gtest src
    && wget -q -O - https://github.com/google/googletest/archive/release-${GOOGLETEST_VERSION}.tar.gz \
        | tar -xzf - \
    && mv googletest-* gtest \
    ## Build protobuf
    && ./autogen.sh \
    && CXXFLAGS="$CXXFLAGS -fno-delete-null-pointer-checks" ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
    && make \
    && make check \
    && make install \
    ## Cleanup
    && apk del build-dependencies \
    && rm -rf /root/.cache \
    && rm -rf *.tgz *.tar *.zip \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Install Hadoop
RUN set -x \
    ## Install dependency lib 
    && apk add --no-cache --upgrade --virtual=build-dependencies su-exec openssl ca-certificates \
    && update-ca-certificates \
    ## Download hadoop bin
    && mirror_url=$( \
        wget -q -O - "http://www.apache.org/dyn/closer.cgi/?as_json=1" \
        | grep "preferred" \
        | sed -n 's#.*"\(http://*[^"]*\)".*#\1#p' \
        ) \
    && wget -q -c ${mirror_url}/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && wget -q -c https://dist.apache.org/repos/dist/release/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.asc \
    && wget -q -c https://dist.apache.org/repos/dist/release/hadoop/common/KEYS \
    && gpg --import KEYS \
    && gpg --verify hadoop-${HADOOP_VERSION}.tar.gz.asc hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzvf hadoop-${HADOOP_VERSION}.tar.gz -C /tmp \
    && mv /tmp/hadoop-* ${HADOOP_HOME} \
    && rm -rf hadoop-${HADOOP_VERSION}.tar.gz hadoop-${HADOOP_VERSION}.tar.gz.asc KEYS \
    ## Make soft link
    && ln -s HADOOP_CONF_DIR /etc/hadoop \
    && ln -s /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop-${HADOOP_VERSION%.*} \
    ## Add profile
    && env \
       | grep -E '^(JAVA|HADOOP|PATH|YARN)' \
       | sed 's/^/export /g' \
       > ~/.profile \
    && cp ~/.profile /etc/profile.d/hadoop \
    && sed -i 's@${JAVA_HOME}@'${JAVA_HOME}'@g' ${HADOOP_CONF_DIR}/hadoop-env.sh \
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
    && chown -R yarn:hadoop \
        ${HADOOP_TMP_DIR}/yarn \
        ${HADOOP_TMP_DIR}/nm-local-dir \
        ${HADOOP_TMP_DIR}/yarn-nm-recovery \
        ${YARN_LOG_DIR} \
    && chown -R mapred:hadoop \
        ${HADOOP_TMP_DIR}/mapred  \
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
    && rm /hadoop-${HADOOP_VERSION}.tar.gz \
    && rm -rf /root/.cache \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

COPY etc/*  ${HADOOP_CONF_DIR}/
COPY bin/*  ${HADOOP_HOME}/

WORKDIR ${HADOOP_HOME}

VOLUME ["${HADOOP_TMP_DIR}", "${HADOOP_LOG_DIR}", "${YARN_LOG_DIR}", "${HADOOP_HOME}"]

EXPOSE 8088 50070

CMD ["/bin/sh","bootstrap.sh"]