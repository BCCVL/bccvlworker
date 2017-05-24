
// we need a node with docker available
node('docker') {

    // set unique image name ... including BUILD_NUMBER to support parallel builds
    def basename = 'hub.bccvl.org.au/bccvl/bccvlworker'
    def imgversion = env.BUILD_NUMBER
    // variable to hold docker image object
    def img = null
    // variable to hold visualiser version
    def version = null


    def pip_pre = "True"
    if (params.stage == 'prod') {
        // no pre releases allowed for prod build
        pip_pre = "False"
    }

    def PYPI_INDEX_CRED = 'pypi_index_url_dev'
    if (params.stage == 'rc' || params.stage == 'prod') {
        // no dev pre releases for rc and prod
        PYPI_INDEX_CRED = 'pypi_index_url_prod'
    }

    try {
        // fetch source
        stage('Checkout') {

            checkout scm

        }

        // build image
        stage('Build') {

            // getRequirements from last BCCVL Visualiser 'release' branch build
            if (params.stage == 'rc' || params.stage == 'prod') {
                getRequirements('org.bccvl.tasks_tags')
            } else {
                getRequirements('org.bccvl.tasks/master')
            }

            withCredentials([string(credentialsId: PYPI_INDEX_CRED, variable: 'PYPI_INDEX_URL')]) {
                docker.withRegistry('https://hub.bccvl.org.au', 'hub.bccvl.org.au') {
                    img = docker.build("${basename}:${imgversion}",
                                       "--rm --pull --no-cache --build-arg PIP_INDEX_URL=${PYPI_INDEX_URL} --build-arg PIP_PRE=${pip_pre} . ")
                }
            }
            // get version:
            img.inside() {
                version = sh(script: 'python -c  \'import pkg_resources; print pkg_resources.get_distribution("org.bccvl.tasks").version\'',
                             returnStdout: true).trim()
            }
            // now we know the version ... re-tag and delete old tag
            imgversion = version.replaceAll('\\+','_') + '-' + env.BUILD_NUMBER
            img = reTagImage(img, basename, imgversion)
        }


        // test image
        stage('Test') {

            // run unit tests inside built image
            withCredentials([string(credentialsId: PYPI_INDEX_CRED, variable: 'PYPI_INDEX_URL')]) {
                img.inside("-u root --env PIP_INDEX_URL=${PYPI_INDEX_URL}") {
                    // get install location
                    def testdir=sh(script: 'python -c \'import os.path, org.bccvl.tasks; print os.path.dirname(org.bccvl.tasks.__file__)\'',
                                   returnStdout: true).trim()
                    // install test dependies
                    // TODO: would be better to use some requirements file to pin versions
                    sh "pip install org.bccvl.tasks[test]==${version}"
                    // run tests
                    sh "nosetests -w ${testdir}"
                }
            }

            // check if tests ran fine
            if (currentBuild.result != null && currentBuild.result != 'SUCCESS') {
                // failed
            }

        }

                // publish image to registry
        stage('Publish') {

            if (currentBuild.result == null || currentBuild.result == 'SUCCESS') {
                // success

                // if it is a dev version we push it as latest
                if (isDevVersion(version)) {
                    // re tag as latest
                    img = reTagImage(img, basename, 'latest')
                }
                docker.withRegistry('https://hub.bccvl.org.au', 'hub.bccvl.org.au') {
                    img.push()
                }

                slackSend color: 'good', message: "New Image ${img.id}\n${env.JOB_URL}"

            }

        }

    }
    catch (err) {
        echo "Running catch"
        throw err
    }
    finally {
        stage('Cleanup') {
            // clean up image
            if (img != null) {
                sh "docker rmi ${img.id}"
            }
        }
    }

}
