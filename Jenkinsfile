pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            args "-u root --entrypoint=''"
        }
    }

    environment {
        // Hetzner Token
        TF_VAR_hcloud_token = credentials('hcloud_token')
        // HCP Terraform Token (must be this exact variable name)
        TF_TOKEN_app_terraform_io = credentials('hcp-terraform-token')
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }
        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }
    }
}