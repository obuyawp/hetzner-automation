pipeline {
    agent any
    
    stages {
        stage('Terraform Plan') {
            steps {
                script {
                
                    sh "terraform plan -no-color > plan_output.txt"
                    env.TF_SUMMARY = sh(script: "grep 'Plan:' plan_output.txt || echo 'No changes detected'", returnStdout: true).trim()
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }
    }

    post {
        success {
            slackSend(
                color: 'good', 
                message: "✅ *Hetzner Deployment Successful*\n" +
                         "*Build:* #${env.BUILD_NUMBER}\n" +
                         "*Status:* ${env.TF_SUMMARY}\n" +
                         "*Action:* Check the console here: ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                color: 'danger', 
                message: "❌ *Hetzner Deployment Failed*\n" +
                         "*Build:* #${env.BUILD_NUMBER}\n" +
                         "*Error:* Check logs immediately: ${env.BUILD_URL}"
            )
        }
    }
}