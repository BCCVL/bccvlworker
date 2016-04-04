FROM hub.bccvl.org.au/bccvl/workerbase:1.1.0

RUN yum install -y git python-devel gmp-devel gdal-python exempi-devel && \
    yum clean all

RUN curl https://bootstrap.pypa.io/get-pip.py | python2.7

ENV WORKER_HOME /opt/worker
ENV WORKER_CONF /etc/opt/worker

RUN groupadd -g 415 worker && \
    useradd -u 415 -g 415 -d $WORKER_HOME -m -s /bin/bash worker

COPY files/requirements.txt $WORKER_HOME/

WORKDIR $WORKER_HOME

RUN pip2.7 install setuptools==19.6.1
RUN pip2.7 install -r requirements.txt && \
    pip2.7 install -f https://github.com/BCCVL/org.bccvl.movelib/archive/1.1.0.tar.gz#egg=org.bccvl.movelib-1.1.0 org.bccvl.movelib[http,scp,swift]==1.1.0 && \
    pip2.7 install -f https://github.com/BCCVL/org.bccvl.tasks/archive/1.10.0.tar.gz#egg=org.bccvl.tasks-1.10.0 org.bccvl.tasks[metadata]==1.10.0

ENV BCCVL_CONFIG ${WORKER_CONF}/bccvl.ini
COPY files/bccvl.ini $BCCVL_CONFIG

ENV WORKDIR /var/opt/worker
RUN mkdir -p $WORKDIR && \
    chown -R worker:worker $WORKDIR

CMD celery worker --app=org.bccvl.tasks --queues=worker --hostname=worker@bccvl -I org.bccvl.tasks.compute --uid=415 --gid=415
