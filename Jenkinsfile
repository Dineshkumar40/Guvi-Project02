pipeline {

    agent any

    environment {
        DOCKER_IMAGE = 'dineshkumar40/trend-app'
        DOCKER_TAG = "${BUILD_NUMBER}"
        AWS_REGION = 'ap-south-1'
        EKS_CLUSTER = 'trend-eks'
        DOCKER_CREDENTIALS = credentials('dockerhub-creds')
    }
    stages {
        // 1. CHECKOUT
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        // 2. BUILD DOCKER IMAGE
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "Building Docker Image"
                    echo "=========================================="
                    docker build \
                      -t ${DOCKER_IMAGE}:${DOCKER_TAG} \
                      -t ${DOCKER_IMAGE}:latest \
                      .
                    echo "Docker image built successfully"
                    docker images | grep trend-app
                '''
            }
        }
        // 3. DOCKERHUB LOGIN
        stage('DockerHub Login') {
            steps {
                sh '''
                    echo "$DOCKER_CREDENTIALS_PSW" | \
                    docker login \
                    -u "$DOCKER_CREDENTIALS_USR" \
                    --password-stdin
                '''
            }
        }
        // 4. PUSH TO DOCKERHUB
        stage('Push Docker Image') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "Pushing Docker Image"
                    echo "=========================================="
                    docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                    echo "Docker image pushed successfully"
                '''
            }
        }
        // 5. CONFIGURE EKS
        stage('Configure EKS') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "Configuring EKS"
                    echo "=========================================="
                    aws eks update-kubeconfig \
                      --region ${AWS_REGION} \
                      --name ${EKS_CLUSTER}
                    echo "Current Kubernetes context:"
                    kubectl config current-context
                '''
            }
        }
        // 6. UPDATE DEPLOYMENT IMAGE
        stage('Update Kubernetes Image') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "Updating Kubernetes Deployment Image"
                    echo "=========================================="
                    echo "Before sed:"
                    grep "image:" deployment.yaml
                    sed -i \
                      "s|image: IMAGE_PLACEHOLDER|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|g" \
                      deployment.yaml
                    echo "After sed:"
                    grep "image:" deployment.yaml
                '''
            }
        }
        // 7. DEPLOY TO EKS
        stage('Deploy to EKS') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "Deploying to EKS"
                    echo "=========================================="
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                    echo "Kubernetes resources applied successfully"
                '''
            }
        }
        // 8. WAIT FOR DEPLOYMENT
        stage('Wait for Deployment') {
            steps {
                sh '''
                    echo "=========================================="
                    echo "Waiting for Deployment"
                    echo "=========================================="
                    kubectl rollout status \
                      deployment/trend-app \
                      --timeout=180s
                    echo "Deployment completed successfully"
                '''
            }
        }
        // 9. SHOW PODS AND SERVICE
        stage('Get Application URL') {
            steps {
                script {
                    sh '''
                        echo "=========================================="
                        echo "Pods"
                        echo "=========================================="
                        kubectl get pods -o wide

                        echo ""
                        echo "=========================================="
                        echo "Service"
                        echo "=========================================="
                        kubectl get service trend-service
                    '''
                    env.APP_URL = sh(
                        script: '''
                            kubectl get service trend-service \
                              -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:3000'
                        ''',
                        returnStdout: true
                    ).trim()
                    echo "Application URL: ${env.APP_URL}"
                }
            }
        }
    }

    // POST ACTIONS
    post {
        // SUCCESS
        success {
            echo '=========================================='
            echo 'Trend Application Deployed Successfully!'
            echo '=========================================='
            echo "Application URL: ${env.APP_URL}"
            emailext(
                subject: "SUCCESS: Trend Deployment - Build #${BUILD_NUMBER}",
                body: """
                    Hello,
                    The Trend application has been successfully deployed.
                    Build Number:${BUILD_NUMBER}
                    Docker Image:${DOCKER_IMAGE}:${DOCKER_TAG}
                    EKS Cluster:${EKS_CLUSTER}
                    AWS Region:${AWS_REGION}
                    Application URL:${env.APP_URL}
                    Jenkins Job:${JOB_NAME}
                    Build URL:${BUILD_URL}
                    Status:SUCCESS
                    Regards,
                    Jenkins
                    """,
                to: "dineshappleoneplus@gmail.com"
            )
        }
        // FAILURE

        failure {
            echo '=========================================='
            echo 'Trend Deployment Failed!'
            echo '=========================================='
            emailext(
                subject: "Failed: Trend Deployment - Build #${BUILD_NUMBER}",
                body: """
                    Hello,
                    The Trend application deployment has failed.
                    Build Number:${BUILD_NUMBER}
                    Docker Image:${DOCKER_IMAGE}:${DOCKER_TAG}
                    EKS Cluster:${EKS_CLUSTER}
                    AWS Region:${AWS_REGION}
                    Jenkins Job:${JOB_NAME}
                    Build URL:${BUILD_URL}
                    Status:Failed
                    Please check the Jenkins console output.
                    """,
                to: "dineshappleoneplus@gmail.com"
            )
        }
        // ALWAYS
        always {
            sh '''
                docker logout || true
            '''
            echo "Pipeline completed."
        }
    }
}