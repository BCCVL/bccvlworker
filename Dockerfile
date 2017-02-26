FROM hub.bccvl.org.au/bccvl/workerbase:2017-02-25

RUN yum install -y \
    git \
    python-devel \
    gmp-devel \
    exempi-devel \
    && yum clean all

ENV WORKER_HOME /opt/worker
ENV WORKER_CONF /etc/opt/worker

RUN groupadd -g 415 worker && \
    useradd -u 415 -g 415 -d $WORKER_HOME -m -s /bin/bash worker

COPY files/requirements.txt $WORKER_HOME/

WORKDIR $WORKER_HOME

RUN export PIP_INDEX_URL=${PIP_INDEX_URL} && \
    export PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST} && \
    export PIP_NO_CACHE_DIR=False && \
    export PIP_PRE=${PIP_PRE} && \
    pip install -r requirements.txt && \
    pip install org.bccvl.tasks[metadata,htp,scp,swift]

ENV BCCVL_CONFIG ${WORKER_CONF}/bccvl.ini
COPY ["files/bccvl.ini", \
      "files/celeryconfig.py" \
      $BCCVL_CONFIG]

ENV WORKDIR /var/opt/worker
RUN mkdir -p $WORKDIR && \
    chown -R worker:worker $WORKDIR

COPY files/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# TODO: celery itself should start as worker
CMD ["celery", "worker", "--app=org.bccvl.tasks", "--queues=worker", \
     "--hostname=worker@%h", "-I", "org.bccvl.tasks.compute", \
     "--uid=worker", "--gid=worker"]
