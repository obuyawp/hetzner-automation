pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            args "-u root --entrypoint=''"
        }
    }

    environment {
        
        TF_TOKEN_app_terraform_io = credentials('hcp-terraform-token')
    
        TF_VAR_hcloud_token       = credentials('hcloud_token')
    }

    stages {
        stage('Terraform Plan') {
            steps {
                script {
                    sh "terraform init"
                    sh "terraform plan -no-color | tee plan_output.txt"
                    env.TF_SUMMARY = sh(
                        script: "grep 'Plan:' plan_output.txt || echo 'No changes detected'", 
                        returnStdout: true
                    ).trim()
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
                channel: 'C0ACD830SBC',
                color: 'good',
                message: "✅ *Hetzner Deployment Successful*\n" +
                         "*Build:* #${env.BUILD_NUMBER}\n" +
                         "*Status:* ${env.TF_SUMMARY}\n" +
                         "*Link:* ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                channel: 'C0ACD830SBC',
                color: 'danger',
                message: "❌ *Hetzner Deployment Failed*\n" +
                         "*Build:* #${env.BUILD_NUMBER}\n" +
                         "*Error:* Check logs immediately: ${env.BUILD_URL}"
            )
        }
    }
}