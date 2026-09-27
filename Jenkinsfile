pipeline {
    agent any

    environment {
        DOCKER_IMAGE = '22692366/isec6000-express-sample'
    }

    options {
        buildDiscarder(logRotator(
            numToKeepStr: '10',
            artifactNumToKeepStr: '5'
        ))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out application source code'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    docker.image('node:16').inside('-u 1000:1000') {
                        sh '''
                            node --version
                            npm --version
                            npm ci
                        '''
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    docker.image('node:16').inside('-u 1000:1000') {
                        sh '''
                            mkdir -p reports
                            set +e

                            npm audit --omit=dev --audit-level=high \
                                > reports/npm-audit.txt 2>&1

                            AUDIT_STATUS=$?
                            set -e

                            cat reports/npm-audit.txt
                            exit "$AUDIT_STATUS"
                        '''
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    docker.image('node:16').inside('-u 1000:1000') {
                        sh 'npm test'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                        -t "${DOCKER_IMAGE}:${BUILD_NUMBER}" \
                        -t "${DOCKER_IMAGE}:latest" .
                '''
            }
        }

        stage('Publish Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" |
                            docker login \
                                --username "$DOCKERHUB_USER" \
                                --password-stdin

                        docker push "DOCKERIMAGE:{BUILD_NUMBER}"
                        docker push "${DOCKER_IMAGE}:latest"
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            junit testResults: 'reports/junit.xml',
                  allowEmptyResults: true

            archiveArtifacts artifacts: 'reports/**/*,package-lock.json',
                             allowEmptyArchive: true,
                             fingerprint: true
        }

        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Review the failed stage and console log.'
        }
    }
}
