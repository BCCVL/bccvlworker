FROM hub.bccvl.org.au/bccvl/workerbase:1.0.0

RUN yum install -y git python-devel gmp-devel gdal-python exempi-devel && \
    yum clean all

RUN curl https://bootstrap.pypa.io/get-pip.py | python2.7

ENV WORKER_HOME /opt/worker
ENV WORKER_CONF /etc/opt/worker

RUN groupadd -g 415 worker && \
    useradd -u 415 -g 415 -d $WORKER_HOME -m -s /bin/bash worker

COPY files/requirements.txt $WORKER_HOME/
COPY files/celery.json $WORKER_CONF/

WORKDIR $WORKER_HOME

RUN pip2.7 install setuptools==19.6.1
RUN pip2.7 install -r requirements.txt

ENV WORKDIR /var/opt/worker
RUN mkdir -p $WORKDIR && \
    chown -R worker:worker $WORKDIR

CMD celery worker --app=org.bccvl.tasks --queues=worker --hostname=worker@bccvl -I org.bccvl.tasks.compute --uid=415 --gid=415
