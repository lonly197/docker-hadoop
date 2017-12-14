FROM lonly/docker-hadoop:2.9.0-base

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

WORKDIR ${HADOOP_HOME}

VOLUME ["${HADOOP_TMP_DIR}", "${HADOOP_LOG_DIR}", "${YARN_LOG_DIR}", "${HADOOP_HOME}"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088

COPY etc/*  ${HADOOP_CONF_DIR}/
COPY bin/*  /usr/local/bin/
COPY lib/*  /usr/local/lib/

ENTRYPOINT ["/bin/sh","/usr/local/bin/bootstrap.sh"]