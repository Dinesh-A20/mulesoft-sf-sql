pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    tools {
        maven 'Maven-3.9'
        jdk 'JDK-17'
    }

    environment {
        APP_NAME = 'salesforce-to-sql-integration'
        DEPLOY_ENV = "${params.DEPLOY_ENV ?: 'Sandbox'}"
        REGION = "${params.REGION ?: 'us-east-1'}"
        WORKER_TYPE = "${params.WORKER_TYPE ?: 'MICRO'}"
        WORKERS = "${params.WORKERS ?: '1'}"
    }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['Sandbox', 'QA', 'Production'], description: 'Anypoint environment')
        choice(name: 'REGION', choices: ['us-east-1', 'us-east-2', 'us-west-2', 'eu-west-1'], description: 'CloudHub region')
        choice(name: 'WORKER_TYPE', choices: ['MICRO', 'SMALL', 'MEDIUM', 'LARGE'], description: 'Worker size')
        string(name: 'WORKERS', defaultValue: '1', description: 'Number of workers')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit and MUnit Tests') {
            steps {
                withCredentials([
                    string(credentialsId: 'mule-secure-key', variable: 'MULE_SECURE_KEY')
                ]) {
                    sh 'mvn --batch-mode clean test -Dmule.secure.key=$MULE_SECURE_KEY -Denv=qa'
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'target/site/munit/coverage',
                        reportFiles: 'munit-coverage.html',
                        reportName: 'MUnit Coverage'
                    ])
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn --batch-mode clean package -DskipMunitTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Deploy to CloudHub') {
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'anypoint-deployment', usernameVariable: 'ANYPOINT_USERNAME', passwordVariable: 'ANYPOINT_PASSWORD'),
                    string(credentialsId: 'mule-secure-key', variable: 'MULE_SECURE_KEY')
                ]) {
                    sh '''
                        mvn --batch-mode deploy -DmuleDeploy \
                          -DskipMunitTests \
                          -Danypoint.username=$ANYPOINT_USERNAME \
                          -Danypoint.password=$ANYPOINT_PASSWORD \
                          -DapplicationName=$APP_NAME \
                          -Denvironment=$DEPLOY_ENV \
                          -Dregion=$REGION \
                          -DworkerType=$WORKER_TYPE \
                          -Dworkers=$WORKERS \
                          -Dmule.secure.key=$MULE_SECURE_KEY \
                          -Denv=prod
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
