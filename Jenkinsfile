pipeline {
    agent {
        docker {
            image 'node:18-buster'
            args '-u 996:993 -p 8081:8080'
        }
    }

    environment {
        NVM_DIR = "/var/lib/jenkins/workspace/train-schedule_master/.nvm"
        NPM_CONFIG_CACHE = "/var/lib/jenkins/workspace/train-schedule_master/.npm"
    }

    stages {
        stage('Setup') {
            steps {
                script {
                    // Install nvm and use it within the container
                    sh '''
                        export NVM_DIR="/var/lib/jenkins/workspace/train-schedule_master/.nvm"
                        export NPM_CONFIG_CACHE="/var/lib/jenkins/workspace/train-schedule_master/.npm"
                        mkdir -p $NVM_DIR
                        mkdir -p $NPM_CONFIG_CACHE
                        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
                        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                        nvm install 18.17.0
                        nvm use 18.17.0
                        npm install -g npm@latest
                    '''
                }
            }
        }

        stage('Build') {
            steps {
                echo 'Running build automation'
                sh './gradlew build --no-daemon'
                archiveArtifacts artifacts: 'dist/trainSchedule.zip'
            }
        }

        stage('Build Docker Image') {
            when {
                branch 'master'
            }
            steps {
                script {
                    app = docker.build("willbla/train-schedule")
                    app.inside {
                        sh 'echo $(curl localhost:8080)'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            when {
                branch 'master'
            }
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker_hub_login') {
                        app.push("${env.BUILD_NUMBER}")
                        app.push("latest")
                    }
                }
            }
        }

        stage('DeployToProduction') {
            when {
                branch 'master'
            }
            steps {
                input 'Deploy to Production?'
                milestone(1)
                withCredentials([usernamePassword(credentialsId: 'webserver_login', usernameVariable: 'USERNAME', passwordVariable: 'USERPASS')]) {
                    script {
                        sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@$prod_ip \"docker pull willbla/train-schedule:${env.BUILD_NUMBER}\""
                        try {
                            sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@$prod_ip \"docker stop train-schedule\""
                            sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@$prod_ip \"docker rm train-schedule\""
                        } catch (err) {
                            echo "caught error: ${err}"
                        }
                        sh "sshpass -p '$USERPASS' -v ssh -o StrictHostKeyChecking=no $USERNAME@$prod_ip \"docker run --restart always --name train-schedule -p 8080:8080 -d willbla/train-schedule:${env.BUILD_NUMBER}\""
                    }
                }
            }
        }
    }
}
