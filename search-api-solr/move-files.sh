#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

mv /opt/solr/server/solr/configsets/_default /opt/docker-solr/configsets/
mv /opt/solr/server/solr/configsets/sample_techproducts_configs /opt/docker-solr/configsets/
mv /opt/solr/server/solr/solr.xml /opt/docker-solr/solr.xml
if [[ -d /tmp/configsets/"${SOLR_VER:0:1}"/ ]]; then 
    cp -R /tmp/configsets/"${SOLR_VER:0:1}"/* /opt/docker-solr/configsets/
fi
chown -R solr:solr /opt/docker-solr/configsets