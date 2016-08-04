
node {
    // fetch source
    stage 'Checkout'

    checkout scm

    // build image
    stage 'Build'

    def imagename = 'hub.bccvl.org.au/bccvl/bccvlworker'
    def img = docker.build(imagename)

    // test image
    stage 'Test'

    echo "Not activated yet"

    // publish image to registry
    stage 'Publish'

    def imagetag = 1.13.2
    img.push(imagetag)
}
