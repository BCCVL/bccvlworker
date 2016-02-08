BCCVL Worker
============

Celery worker instance to process BCCVL compute jobs.

Configuration
-------------

Depending on environment, it amy be necessary to overrid the Celery configuration file in /etc/opt/worker/celery.json

If running multiple instances of thes container it is also necessary to apapt the command line options. i.e. --hostname, -I to load required tasks submodules, and --queues to listen on the correct queue.

The worker reads the configuration from $CELER_JSON_CONFIG.

Data Storage
------------

All temporary work data is stored in $WORKDIR (/var/opt/worker).

Build
-----

.. code-block:: Shell

  docker build --rm=true -t hub.bccvl.org.au/bccvl/bccvlworker:1.0.0 .

Publish
-------

.. code-block:: Shell

  docker push hub.bccvl.org.au/bccvl/bccvlworker:1.0.0
