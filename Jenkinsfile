
def imagename;
def imagetag;

node {
    // fetch source
    stage 'Checkout'

    // check out main repo
    checkout scm

    // clone depentent repos
    // map sub repos to branch/tag refs
    // has to be a list of lists otherwise we can't use plain c-style iteration.
    //     other types of iteration usually involve an iterator which can't be serialized and would require some @NonCPS workaround
    def subrepos = [
        ['org.bccvl.movelib', 'refs/heads/develop'],
        ['org.bccvl.tasks', 'refs/heads/develop']
    ]
    // iterate over map and clone into current workspace subfolder
    for (int i=0; i<subrepos.size(); i++) {
        def repo = subrepos[i][0]
        def refspec = subrepos[i][1]
        checkout(poll: false,
                 scm: [$class: 'GitSCM',
                       branches: [[name: refspec],
                       extensions: [
                           [$class: 'RelativeTargetDirectory', relativeTargetDir: "src/${repo}"],
                           [$class: 'CleanBeforeCheckout'],
                           [$class: 'PruneStaleBranch']
                        ],
                        userRemoteConfigs: [
                            [url: "https://github.com/BCCVL/${repo}"]
                        ]
                    ]
                )
    }

    // build image
    stage 'Build Image'

    imagename = 'hub.bccvl.org.au/bccvl/bccvlworker'
    def img = docker.build(imagename)

    // test image
    stage 'Test'

    docker.image(imagename).inside("-u root") {

        // capture installed package versions and store in workspace
        sh('pip freeze > versions.txt')

        sh('pip install nose2 cov-core mock')
        sh('nosetests --with-xunit --with-coverage --cover-package=org.bccvl --cover-xml --cover-html org.bccvl')

        // capture unit test outputs in jenkins
        step([$class: 'JUnitResultArchiver', testResults: 'nosetests.xml'])

        // capture coverage report
        publishHTML(target:[allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'cover', reportFiles: 'index.html', reportName: 'Coverage Report'])
    }

    imagetag = getPipVersion("versions.txt", "org.bccvl.tasks")

    // publish image to registry
    switch(env.BRANCH_NAME) {
        case 'develop':

            img.push('latest')

        case 'master':
        case 'qa':
            stage 'Image Push'

            img.push(imagetag)

            slackSend color: 'good', message: "New Image ${imagename}:${imagetag}\n${env.JOB_URL}"

            break
    }

}

switch(env.BRANCH_NAME) {

    case 'master':

        stage 'Approve'

        mail(to: 'g.weis@griffith.edu.au',
             subject: "Job '${env.JOB_NAME}' (${env.BUILD_NUMBER}) is waiting for input",
             body: "Please go to ${env.BUILD_URL}.");

        slackSend color: 'good', message: "Ready to deploy ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"

        input 'Ready to deploy?';

    case 'develop':
    case 'qa':

        stage 'Deploy'

        node {

            deploy("Worker", env.BRANCH_NAME, "${imagename}:${imagetag}")

            slackSend color: 'good', message: "Deployed ${env.JOB_NAME} ${env.BUILD_NUMBER}"

        }

        break

}
