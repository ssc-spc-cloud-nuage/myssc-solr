#!/bin/bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

WORKDIR="/opt/solr/server/home"

sudo init_volumes

# Moved into init_volumed
# mkdir -p /opt/solr/server/solr/configsets

# migrate

# Symlinks config sets to volume.
for configset in $(ls -d /opt/docker-solr/configsets/*); do
    if [[ ! -d "${WORKDIR}/configsets/${configset##*/}" ]]; then
        sudo ln -s "${configset}" "${WORKDIR}"/configsets/;
    fi
done

if [[ ! -f "${WORKDIR}"/solr.xml ]]; then
    sudo ln -s /opt/docker-solr/solr.xml "${WORKDIR}"/solr.xml
fi

if [[ -f /opt/solr/bin/solr.in.sh ]]; then
    conf_file=/opt/solr/bin/solr.in.sh
else
    conf_file=/etc/default/solr.in.sh
fi

# sed -E -i 's@^#SOLR_HEAP=".*"@'"SOLR_HEAP=${SOLR_HEAP}"'@' "${conf_file}"

if [[ "${1}" == 'make' ]]; then
    exec "$@" -f /usr/local/bin/actions.mk
else
    exec /opt/docker-solr/scripts/docker-entrypoint.sh "$@"
fi
