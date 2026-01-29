pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            args "-u root --entrypoint=''"
        }
    }

    environment {
        TF_VAR_hcloud_token = credentials('hcloud-token')
    }

    stages {
        stage('Debug Token') {
            steps {
                // This will tell us the exact character count
                sh 'echo -n $TF_VAR_hcloud_token | wc -c'
            }
        }
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