pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            args "-u root --entrypoint=''"
        }
    }
    environment {
        // Updated to match your specific Credential ID
        TF_TOKEN_app_terraform_io = credentials('hcp-terraform-token')
        HCLOUD_TOKEN = credentials('hcloud_token')
    }
    stages {
        stage('Terraform Plan') {
            steps {
                script {
                    sh "terraform init"
                    sh "terraform plan -no-color > plan_output.txt"
                    // Extract the plan summary for Slack
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
        always {
            slackSend(
                
                channel: 'C0ACD830SBC', 
                color: currentBuild.currentResult == 'SUCCESS' ? 'good' : 'danger',
                message: "*Build:* #${env.BUILD_NUMBER}\n*Status:* ${currentBuild.currentResult}\n*Terraform:* ${env.TF_SUMMARY ?: 'Plan failed'}\n*Logs:* ${env.BUILD_URL}"
            )
        }
    }
}