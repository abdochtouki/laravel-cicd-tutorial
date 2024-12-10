pipeline {
    agent any
    stages {
        stage("Verify tooling") {
            steps {
                sh '''
                    docker info
                    docker version
                    docker compose version
                '''
            }
        }
        stage("Verify SSH connection to server") {
            steps {
                sshagent(credentials: ['ubuntu-vm-ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@<SERVER_IP> whoami
                    '''
                }
            }
        }        
        stage("Clear all running Docker containers") {
            steps {
                script {
                    try {
                        sh 'docker rm -f $(docker ps -a -q) || echo "No running containers to clear."'
                    } catch (Exception e) {
                        echo 'Error clearing containers: ' + e.getMessage()
                    }
                }
            }
        }
        stage("Start Docker") {
            steps {
                sh 'make up'
                sh 'docker compose ps'
            }
        }
        stage("Run Composer Install") {
            steps {
                sh 'docker compose run --rm composer install'
            }
        }
        stage("Populate .env file") {
            steps {
                dir("/var/lib/jenkins/workspace/envs/laravel-test") {
                    fileOperations([
                        fileCopyOperation(
                            excludes: '', 
                            flattenFiles: true, 
                            includes: '.env', 
                            targetLocation: "${WORKSPACE}"
                        )
                    ])
                }
            }
        }              
        stage("Run Tests") {
            steps {
                sh 'docker compose run --rm artisan test'
            }
        }
    }
    post {
        success {
            script {
                sh 'cd "/var/lib/jenkins/workspace/LaravelTest"'
                sh 'rm -rf artifact.zip'
                sh 'zip -r artifact.zip . -x "*node_modules**"'
            }
            withCredentials([sshUserPrivateKey(credentialsId: 'ubuntu-vm-ssh', keyFileVariable: 'keyfile')]) {
                sh '''
                    scp -v -o StrictHostKeyChecking=no -i ${keyfile} \
                        /var/lib/jenkins/workspace/LaravelTest/artifact.zip \
                        abdo@192.168.1.9:/home/ubuntu/artifact
                '''
            }
            sshagent(credentials: ['ubuntu-vm-ssh']) {
                sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@<SERVER_IP> \
                        "unzip -o /home/ubuntu/artifact/artifact.zip -d /var/www/html"
                    ssh -o StrictHostKeyChecking=no ubuntu@<SERVER_IP> \
                        "sudo chmod -R 777 /var/www/html/storage"
                '''
            }                                  
        }
        always {
            sh 'docker compose down --remove-orphans -v'
            sh 'docker compose ps'
        }
    }
}
