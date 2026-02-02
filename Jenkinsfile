pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            args "-u root --entrypoint=''"
        }
    }
    
    stages {
        stage('Terraform Plan') {
            steps {
                script {
                    // This now runs inside the Hashicorp container where 'terraform' exists
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
                channel: 'C08XXXXXXXX', // Use your Channel ID
                color: 'good', 
                message: "✅ *Hetzner Deployment Successful*\n" +
                         "*Build:* #${env.BUILD_NUMBER}\n" +
                         "*Status:* ${env.TF_SUMMARY}\n" +
                         "*Action:* ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: 'C08XXXXXXXX',
                color: 'danger', 
                message: "❌ *Hetzner Deployment Failed*\n" +
                         "*Build:* #${env.BUILD_NUMBER}\n" +
                         "*Error:* Terraform failed or command not found. Check: ${env.BUILD_URL}"
            )
        }
    }
}