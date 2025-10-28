pipeline {
    agent any
    
    parameters {
        choice(
            name: 'DEPLOYMENT_COLOR',
            choices: ['blue', 'green'],
            description: 'Choose deployment version'
        )
        booleanParam(
            name: 'SWITCH_TRAFFIC',
            defaultValue: false,
            description: 'Switch traffic after deployment'
        )
    }
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'main', 
                url: 'https://github.com/YOUR_USERNAME/blue-green-deployment.git'
            }
        }
        
        stage('Build and Push Docker Image') {
            steps {
                script {
                    if (params.DEPLOYMENT_COLOR == 'blue') {
                        sh '''
                            sed 's/VERSION_COLOR/#0000FF/g; s/VERSION_NAME/BLUE/g; s/VERSION_NUMBER/1.0/g' app/index.html > app/index-temp.html
                            mv app/index-temp.html app/index.html
                            docker build -t $DOCKERHUB_CREDENTIALS_USR/blue-green-app:blue .
                            docker login -u $DOCKERHUB_CREDENTIALS_USR -p $DOCKERHUB_CREDENTIALS_PSW
                            docker push $DOCKERHUB_CREDENTIALS_USR/blue-green-app:blue
                        '''
                    } else {
                        sh '''
                            sed 's/VERSION_COLOR/#00FF00/g; s/VERSION_NAME/GREEN/g; s/VERSION_NUMBER/2.0/g' app/index.html > app/index-temp.html
                            mv app/index-temp.html app/index.html
                            docker build -t $DOCKERHUB_CREDENTIALS_USR/blue-green-app:green .
                            docker login -u $DOCKERHUB_CREDENTIALS_USR -p $DOCKERHUB_CREDENTIALS_PSW
                            docker push $DOCKERHUB_CREDENTIALS_USR/blue-green-app:green
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    if (params.DEPLOYMENT_COLOR == 'blue') {
                        sh '''
                            sed "s/YOUR_DOCKERHUB_USERNAME/$DOCKERHUB_CREDENTIALS_USR/g" k8s/blue-deployment.yaml | kubectl apply -f -
                            kubectl rollout status deployment/app-blue
                        '''
                    } else {
                        sh '''
                            sed "s/YOUR_DOCKERHUB_USERNAME/$DOCKERHUB_CREDENTIALS_USR/g" k8s/green-deployment.yaml | kubectl apply -f -
                            kubectl rollout status deployment/app-green
                        '''
                    }
                }
            }
        }
        
        stage('Switch Traffic') {
            when {
                expression { params.SWITCH_TRAFFIC == true }
            }
            steps {
                script {
                    sh '''
                        CURRENT_VERSION=$(kubectl get service app-service -o jsonpath='{.spec.selector.version}')
                        if [ "$CURRENT_VERSION" = "blue" ]; then
                            NEW_VERSION="green"
                        else
                            NEW_VERSION="blue"
                        fi
                        kubectl patch service app-service -p "{\\"spec\\":{\\"selector\\":{\\"version\\":\\"$NEW_VERSION\\"}}}"
                        echo "Traffic switched from $CURRENT_VERSION to $NEW_VERSION"
                    '''
                }
            }
        }
        
        stage('Verification') {
            steps {
                sh '''
                    kubectl get deployments
                    kubectl get pods -l app=myapp
                    kubectl get service app-service -o jsonpath='{.spec.selector.version}'
                    echo "Current version: $(kubectl get service app-service -o jsonpath='{.spec.selector.version}')"
                '''
            }
        }
    }
    
    post {
        always {
            echo "Pipeline execution completed"
        }
        success {
            echo "Access your application using: kubectl port-forward service/app-service 8080:80"
        }
    }
}
