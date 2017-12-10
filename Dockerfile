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