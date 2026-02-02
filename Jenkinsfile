pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            args "-u root --entrypoint=''"
        }
    }
    environment {
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        HCLOUD_TOKEN = credentials('hcloud_token')
    }
    stages {
        stage('Terraform Plan') {
            steps {
                script {
                    sh "terraform init" // Always good to ensure init runs in the fresh container
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
        always {
            slackSend(
                channel: 'YOUR_ACTUAL_CHANNEL_ID_HERE', 
                color: currentBuild.currentResult == 'SUCCESS' ? 'good' : 'danger',
                message: "*Build:* #${env.BUILD_NUMBER}\n*Status:* ${currentBuild.currentResult}\n*Summary:* ${env.TF_SUMMARY ?: 'Check logs'}\n*Logs:* ${env.BUILD_URL}"
            )
        }
    }
}