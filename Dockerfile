ARG SOLR_VER

FROM solr:${SOLR_VER} AS build

ARG SOLR_VER

ENV SOLR_HEAP="1024m" \
    SOLR_HOME=/opt/solr/server/home \
    SOLR_VER="${SOLR_VER}"

USER root

COPY search-api-solr /tmp/search-api-solr
COPY configsets /tmp/configsets

RUN set -ex; \
    \
    apt update; \
    apt install -y \
#        bash \
        curl \
        wget \
        grep \
        make \
        sudo; \
    \
    apt install -y \
        jq \
        python3-pip \
        sed; \
    \
    pip install yq; \
    \
    # 8.x version has a symlink and wrong permissions.
    if [[ -d "/opt/solr-${SOLR_VER}" ]]; then \
        rm -rf /opt/solr; \
        mv "/opt/solr-${SOLR_VER}" /opt/solr; \
        chown -R solr:solr /opt/solr /etc/default/; \
        cd /opt/solr; \
    fi; \
    \
    mkdir -p /opt/docker-solr/configsets

RUN bash /tmp/search-api-solr/download.sh; \
    bash /tmp/search-api-solr/move-files.sh

FROM solr:${SOLR_VER}

ARG SOLR_VER

ENV SOLR_HEAP="1024m" \
    SOLR_HOME=/opt/solr/server/home \
    SOLR_VER="${SOLR_VER}"

USER root

RUN set -ex; \
    \
    apt update; \
    apt install -y \
        sudo; \
    \
    # 8.x version has a symlink and wrong permissions.
    if [[ -d "/opt/solr-${SOLR_VER}" ]]; then \
        rm -rf /opt/solr; \
        mv "/opt/solr-${SOLR_VER}" /opt/solr; \
        chown -R solr:solr /opt/solr /etc/default/; \
        cd /opt/solr; \
    fi; \
    echo "mkdir -p /opt/solr/server/home/configsets" >> /usr/local/bin/init_volumes; \
    echo "chown -R solr:solr /opt/solr/server/home" > /usr/local/bin/init_volumes; \
    chmod +x /usr/local/bin/init_volumes; \
    bash -c "echo 'solr ALL=(ALL:ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"; \
    \
    mkdir -p /opt/docker-solr/configsets; \
    mkdir -p /opt/solr/server/home; \
    chown -R solr:solr /opt/solr/server/home; \
    chown -R solr:solr /opt/docker-solr; \
    \
    apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/; \
    rm -rf \
        /tmp/configsets \
        /tmp/search-api-solr \
        /opt/solr/server/solr/mycores \
        /var/cache/apk/*;\
    \
    # Temp fix for log4j vulnerability
    rm -f /opt/solr/server/lib/ext/log4j-1.2-api-2.14.1.jar; \
    rm -f /opt/solr/server/lib/ext/log4j-api-2.14.1.jar; \
    rm -f /opt/solr/server/lib/ext/log4j-core-2.14.1.jar; \
    rm -f /opt/solr/server/lib/ext/log4j-slf4j-impl-2.14.1.jar; \
    rm -f /opt/solr/server/lib/ext/log4j-web-2.14.1.jar

COPY --from=build --chown=solr:solr /opt/docker-solr/configsets /opt/docker-solr/configsets
COPY bin /usr/local/bin
COPY entrypoint.sh /
COPY log4j-bin/* /opt/solr/server/lib/ext/

USER solr

# VOLUME /opt/solr/server/home
WORKDIR /opt/solr/server/home

ENTRYPOINT ["/entrypoint.sh"]
CMD ["solr-foreground"]

