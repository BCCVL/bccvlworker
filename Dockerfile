FROM hub.bccvl.org.au/bccvl/workerbase:2016-08-04

RUN yum install -y git python-devel gmp-devel gdal-python exempi-devel && \
    yum clean all

RUN curl https://bootstrap.pypa.io/get-pip.py | python2.7

ENV WORKER_HOME /opt/worker
ENV WORKER_CONF /etc/opt/worker

RUN groupadd -g 415 worker && \
    useradd -u 415 -g 415 -d $WORKER_HOME -m -s /bin/bash worker

COPY files/requirements.txt $WORKER_HOME/

WORKDIR $WORKER_HOME

RUN pip2.7 --no-cache-dir install --upgrade setuptools && \
    pip2.7 --no-cache-dir install -r requirements.txt

ENV BCCVL_CONFIG ${WORKER_CONF}/bccvl.ini
COPY files/bccvl.ini $BCCVL_CONFIG

ENV WORKDIR /var/opt/worker
RUN mkdir -p $WORKDIR && \
    chown -R worker:worker $WORKDIR

COPY files/celeryconfig.py $WORKER_HOME/
COPY files/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["celery", "worker", "--app=org.bccvl.tasks", "--queues=worker", \
     "--hostname=worker@%h", "-I", "org.bccvl.tasks.compute", \
     "--uid=worker", "--gid=worker"]
