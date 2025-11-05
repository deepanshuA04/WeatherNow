pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_ACCOUNT = '164334671507'
        FRONTEND_REPO = "${env.AWS_ACCOUNT}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com/weathernow-frontend"
        BACKEND_REPO = "${env.AWS_ACCOUNT}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com/weathernow-backend"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Images') {
            steps {
                dir('frontend') {
                    bat 'docker build -t weathernow-frontend:latest .'
                }
                dir('backend') {
                    bat 'docker build -t weathernow-backend:latest .'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    bat '''
                      aws ecr create-repository --repository-name weathernow-frontend --region %AWS_REGION% || ver>nul
                      aws ecr create-repository --repository-name weathernow-backend --region %AWS_REGION% || ver>nul

                                                aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT%.dkr.ecr.%AWS_REGION%.amazonaws.com

                      docker tag weathernow-frontend:latest %FRONTEND_REPO%:latest
                      docker tag weathernow-backend:latest %BACKEND_REPO%:latest

                      docker push %FRONTEND_REPO%:latest
                      docker push %BACKEND_REPO%:latest
                    '''
                }
            }
        }

        stage('Register Task Definitions') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    bat '''
                      rem Register task definitions (files are in repo under ecs/)
                      aws ecs register-task-definition --cli-input-json file://ecs/backend-taskdef.json --region %AWS_REGION%
                      aws ecs register-task-definition --cli-input-json file://ecs/frontend-taskdef.json --region %AWS_REGION%
                    '''
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    bat '''
                      rem Update services to force new deployment (assumes cluster & services created)
                      aws ecs update-service --cluster weathernow-cluster --service weathernow-backend-service --force-new-deployment --region %AWS_REGION% || ver>nul
                      aws ecs update-service --cluster weathernow-cluster --service weathernow-frontend-service --force-new-deployment --region %AWS_REGION% || ver>nul
                    '''
                }
            }
        }
    }

    post {
        always {
            bat 'docker logout || ver>nul'
        }
    }
}