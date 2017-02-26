
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
    if (params.stage == 'rc' || params.stage == 'prod') {
        pip_pre = "False"
    }

    def INDEX_HOST = env.PIP_INDEX_HOST
    def INDEX_URL = "http://${INDEX_HOST}:3141/bccvl/dev/+simple/"
    if (params.stage == 'rc' || params.stage == 'prod') {
        INDEX_URL = "http://${INDEX_HOST}:3141/bccvl/prod/+simple/"
    }

    try {
        // fetch source
        stage('Checkout') {

            checkout scm

        }

        // build image
        stage('Build') {

            // TODO: determine dev or release build (changes pip options)
            img = docker.build("${basename}:${imgversion}",
                               "--rm --pull --no-cache --build-arg PIP_INDEX_URL=${INDEX_URL} --build-arg PIP_TRUSTED_HOST=${INDEX_HOST} --build-arg PIP_PRE=${pip_pre} . ")

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
            img.inside("-u root --env PIP_INDEX_URL=${INDEX_URL} --env PIP_TRUSTED_HOST=${INDEX_HOST}") {
                // get install location
                def testdir=sh(script: 'python -c \'import os.path, org.bccvl.tasks; print os.path.dirname(org.bccvl.tasks.__file__)\'',
                               returnStdout: true).trim()
                    // install test dependies
                    // TODO: would be better to use some requirements file to pin versions
                    sh "pip install org.bccvl.tasks[test]==${version}"
                    // run tests
                    sh "nosetests -w ${testdir} --with-xunit --with-coverage --cover-package=org.bccvl --cover-xml --cover-html org.bccvl"
                }
            }

            // capture unit test outputs in jenkins
            step([$class: 'JUnitResultArchiver', testResults: 'nosetests.xml'])

            // capture coverage report
            publishHTML(target:[allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'cover', reportFiles: 'index.html', reportName: 'Coverage Report'])

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
                img.push()

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
            sh "docker rmi ${img.id}"
        }
    }

}
