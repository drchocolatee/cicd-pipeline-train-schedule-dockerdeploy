pipeline {
    agent any

    environment {
        IMAGE_NAME = 'custom-node-java17:latest'
        NVM_DIR = "/root/.nvm"
        NPM_CONFIG_CACHE = "/root/.npm"
        JAVA_HOME = "/usr/lib/jvm/java-17-amazon-corretto"
        PATH = "$JAVA_HOME/bin:$PATH"
    }

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // Create Dockerfile
                    writeFile file: 'Dockerfile', text: '''
                    FROM node:18-buster

                    # Set environment variables for nvm and npm
                    ENV NVM_DIR /root/.nvm
                    ENV NPM_CONFIG_CACHE /root/.npm
                    ENV JAVA_HOME /usr/lib/jvm/java-17-amazon-corretto
                    ENV PATH $JAVA_HOME/bin:$PATH

                    # Add the Amazon Corretto repository and install Java 17
                    USER root
                    RUN mkdir -p /etc/yum.repos.d && \
                        chmod 755 /etc/yum.repos.d && \
                        curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo && \
                        yum install -y java-17-amazon-corretto-devel curl

                    # Install nvm and Node.js
                    RUN mkdir -p $NVM_DIR && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
                        . $NVM_DIR/nvm.sh && \
                        nvm install 18.17.0 && \
                        nvm use 18.17.0 && \
                        npm install -g npm@latest

                    # Set the working directory to /usr/src/app
                    WORKDIR /usr/src/app

                    # Copy package.json and package-lock.json to the working directory
                    COPY package*.json ./

                    # Install any needed packages
                    RUN npm install

                    # Copy the rest of the application source code to the working directory
                    COPY . .

                    # Make port 8080 available to the world outside this container
                    EXPOSE 8080

                    # Define environment variable
                    ENV NODE_ENV production

                    # Run the app
                    CMD [ "npm", "start" ]
                    '''

                    // Build Docker image
                    sh 'docker build -t $IMAGE_NAME .'
                }
            }
        }

        stage('Run Setup') {
            agent {
                docker {
                    image "${env.IMAGE_NAME}"
                    args '-u root -p 8081:8080'
                }
            }
            steps {
                script {
                    // Install nvm and npm
                    sh '''
                        export NVM_DIR="/root/.nvm"
                        export NPM_CONFIG_CACHE="/root/.npm"
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

        stage('Push Docker Image') {
            when {
                branch 'master'
            }
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker_hub_login') {
                        sh 'docker tag $IMAGE_NAME willbla/train-schedule:${env.BUILD_NUMBER}'
                        sh 'docker push willbla/train-schedule:${env.BUILD_NUMBER}'
                        sh 'docker push willbla/train-schedule:latest'
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
