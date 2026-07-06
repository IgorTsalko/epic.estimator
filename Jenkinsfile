@Library('shared@web') _

pipeline {
  agent none
  options {
      buildDiscarder(logRotator(numToKeepStr: '10'))
      disableConcurrentBuilds(abortPrevious: true)
      gitLabConnection('gitftc')
      parallelsAlwaysFailFast()
  }
  environment {
    VERSION = getVersion()
    PROJECT_NAME = "${JOB_NAME.tokenize('/')[0]}"
    PROJECT_VERSION = "${BRANCH_NAME}+${BUILD_NUMBER}"
  }
  stages {
    stage('Build') {
      agent {
        label 'light'
      }
      stages {
        stage('Build checkout') {
          steps {
            cleanCheckout(scm)
          }
        }
        stage('Build compile') {
          when {
            expression { VERSION != "null" }
          }
          steps {
            script {
              sh "printenv"
              env.IMAGE_ID = buildDockerImage("git.ftc.ru:4567/tsalko/eestimator:$VERSION-$BUILD_NUMBER", "\
                    --build-arg BRANCH_NAME=$BRANCH_NAME \
                    --build-arg GIT_COMMIT=$GIT_COMMIT \
                    --build-arg PROJECT_VERSION=$PROJECT_VERSION \
                    --build-arg BUILD_NUMBER=$BUILD_NUMBER")
            }
          }
        }
        stage('Build deploy') {
          when {
            expression { VERSION != "null" }
          }
          steps {
            script {
              helmPublishAppVersionMicrosTo(["$PROJECT_NAME"], "management-test", "$VERSION")
            }
          }
        }
      }
    }
  }
  post {
    always {
      script {
        node('light') {
          collectPipelineMetrics(
            "http://web-metrics-server.online-staging.dp-k8s-test.ftc.ru:30086/pushmetrics/pipeline",
            env.PROJECT_NAME,
            env.PROJECT_VERSION,
            env.IMAGE_ID
          )
        }
      }
    }
    changed { emailThem() }
    success { updateGitlabCommitStatus name: 'jenkins', state: 'success' }
    unsuccessful { updateGitlabCommitStatus name: 'jenkins', state: 'failed' }
  }
}
