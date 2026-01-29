pipeline {
    agent { docker { image 'hashicorp/terraform:latest'; args '-u root' } }
    environment { HCLOUD_TOKEN = credentials('hcloud-token') }
    stages {
        stage('Init') { steps { sh 'terraform init' } }
        stage('Plan') { steps { sh "terraform plan -var='hcloud_token=${HCLOUD_TOKEN}'" } }
        stage('Apply') { steps { sh "terraform apply -auto-approve -var='hcloud_token=${HCLOUD_TOKEN}'" } }
    }
}