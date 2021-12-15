ARG SOLR_VER

FROM solr:${SOLR_VER}

ARG SOLR_VER

ENV SOLR_HEAP="1024m" \
    SOLR_HOME=/opt/solr/server/solr \
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
    echo "chown solr:solr /opt/solr/server/solr" > /usr/local/bin/init_volumes; \
    chmod +x /usr/local/bin/init_volumes; \
    echo 'solr ALL=(root) NOPASSWD:SETENV: /usr/local/bin/init_volumes' > /etc/sudoers.d/solr; \
    \
    mkdir -p /opt/docker-solr/configsets; \
    bash /tmp/search-api-solr/download.sh; \
    bash /tmp/search-api-solr/move-files.sh; \
    chown -R solr:solr /opt/solr/server/solr; \
    \
    # apk del --purge .solr-build-deps; \
    rm -rf \
        /tmp/configsets \
        /tmp/search-api-solr \
        /opt/solr/server/solr/mycores \
        /var/cache/apk/*

COPY bin /usr/local/bin
COPY entrypoint.sh /

USER solr

VOLUME /opt/solr/server/solr
WORKDIR /opt/solr/server/solr

# ENTRYPOINT ["/entrypoint.sh"]
CMD ["solr-foreground"]
