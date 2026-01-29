pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            // Using double quotes here is often more stable in Groovy
            args "-u root --entrypoint=''"
        }
    }

    environment {
        HCLOUD_TOKEN = credentials('hcloud-token')
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform Plan') {
            steps {
                sh "terraform plan -var='hcloud_token=${HCLOUD_TOKEN}'"
            }
        }
        stage('Terraform Apply') {
            steps {
                sh "terraform apply -auto-approve -var='hcloud_token=${HCLOUD_TOKEN}'"
            }
        }
    }
}