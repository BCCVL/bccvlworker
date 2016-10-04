#!/bin/bash

# make sure our celery worker has access to scratch space ${WORKDIR}
mkdir -p "${WORKDIR}"
chown -R worker:worker "${WORKDIR}"

# ensure SSL key files have proper permissions
if [ -n "${BROKER_USE_SSL_KEYFILE}" ] ; then
  chmod 600 "${BROKER_USE_SSL_KEYFILE}"
fi

# ensure bccvl.ini is not world readable, and accessible by our worker user
chmod 600 "${BCCVL_CONFIG}"
chown worker:worker "${BCCVL_CONFIG}"

# continue with normal startup
exec "$@"
