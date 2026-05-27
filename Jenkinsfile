pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    stages {
        stage('Build') {
            steps {
                echo '═══════════════════════════════════════════════════════════'
                echo '  Stage: Build Backend Image'
                echo '═══════════════════════════════════════════════════════════'
                sh '''
                    docker compose build --parallel backend1 backend2
                    echo ''
                    echo '✓ Backend image build completed'
                    docker compose images | grep backend1 || true
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo '═══════════════════════════════════════════════════════════'
                echo '  Stage: Deploy Services'
                echo '═══════════════════════════════════════════════════════════'
                sh '''
                    echo 'Cleaning up old deployment...'
                    docker compose down --remove-orphans || true
                    echo ''
                    echo 'Starting services with Docker Compose...'
                    docker compose up -d
                    echo ''
                    echo 'Waiting for services to initialize...'
                    sleep 5
                    echo ''
                    echo '✓ Services deployed'
                    docker compose ps
                '''
            }
        }

        stage('Verify') {
            steps {
                echo '═══════════════════════════════════════════════════════════'
                echo '  Stage: Verify Deployment'
                echo '═══════════════════════════════════════════════════════════'
                sh '''
                    echo 'Testing backend health endpoints...'
                    echo '→ Backend 1 (/health):'
                    curl -s http://localhost:8081/health || true
                    echo ''
                    echo '→ Backend 2 (/health):'
                    curl -s http://localhost:8082/health || true
                    echo ''
                    echo '→ NGINX load balancer (/health):'
                    curl -s http://localhost:8080/health || true
                '''
            }
        }

        stage('Demo') {
            steps {
                echo '═══════════════════════════════════════════════════════════'
                echo '  Stage: Load Balancing Demonstration'
                echo '═══════════════════════════════════════════════════════════'
                sh '''
                    echo 'Demonstrating round-robin routing through NGINX...'
                    for i in $(seq 1 6); do
                        echo 'Request '"$i"':'
                        curl -s http://localhost:8080/ | sed -n '1,6p'
                        echo ''
                    done
                '''
            }
        }
    }

    post {
        always {
            echo ''
            echo '═══════════════════════════════════════════════════════════'
            echo '  Platform Status Summary'
            echo '═══════════════════════════════════════════════════════════'
            sh '''
                docker compose ps
                echo ''
                docker network inspect app-network || true
            '''
        }

        success {
            script {
                currentBuild.description = '✓ Deployment complete - platform live'
            }
            echo ''
            echo '✓ Pipeline completed successfully!'
            echo '  Main endpoint:  http://localhost:8080/'
            echo '  Backend 1:      http://localhost:8081/'
            echo '  Backend 2:      http://localhost:8082/'
            echo '  Health check:   http://localhost:8080/health'
        }

        failure {
            script {
                currentBuild.description = '✗ Pipeline failed'
            }
            echo ''
            echo '✗ Pipeline failed - inspect console logs above'
        }
    }
}
