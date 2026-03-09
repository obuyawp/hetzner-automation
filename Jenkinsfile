pipeline {
    agent {
        docker { 
            image 'hashicorp/terraform:latest' 
            args "-u root --entrypoint=''"
        }
    }

    parameters {
        booleanParam(name: 'RUN_POST_PROVISION', defaultValue: true, description: 'Run post-provision scripts on created servers over SSH')
        booleanParam(name: 'RUN_AZURE_AGENT', defaultValue: false, description: 'Run Azure deployment agent setup command')
        booleanParam(name: 'RUN_ZABBIX', defaultValue: true, description: 'Configure Zabbix agent settings')
        booleanParam(name: 'RUN_NETBIRD', defaultValue: true, description: 'Enroll server in NetBird')
        booleanParam(name: 'RUN_WAZUH', defaultValue: true, description: 'Install and configure Wazuh agent')
        booleanParam(name: 'RUN_TENABLE', defaultValue: true, description: 'Install and configure Tenable agent')
        booleanParam(name: 'RUN_HARDENING', defaultValue: false, description: 'Run CIS hardening script')
    }

    environment {
        TF_TOKEN_app_terraform_io = credentials('hcp-terraform-token')
        TF_VAR_hcloud_token       = credentials('hcloud_token')
        GOOGLE_SHEET_WEBHOOK_URL  = 'https://script.google.com/macros/s/AKfycbx4rDpWsTXZVmIfCaHrZV_3ruGBqPuUW40eUP3VzX2udDA1V61-p864AjuXp_L2nYnM/exec'
    }

    stages {
        stage('Terraform Plan') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'server_admin_login', usernameVariable: 'SERVER_ADMIN_USERNAME', passwordVariable: 'SERVER_ADMIN_PASSWORD')
                ]) {
                    script {
                        sh '''
                            if ! command -v openssl >/dev/null 2>&1; then
                              if command -v apk >/dev/null 2>&1; then
                                apk add --no-cache openssl
                              elif command -v apt-get >/dev/null 2>&1; then
                                apt-get update && apt-get install -y openssl
                              else
                                echo "Cannot install openssl in this build container."
                                exit 1
                              fi
                            fi

                            SERVER_ADMIN_PASSWORD_HASH="$(openssl passwd -6 "${SERVER_ADMIN_PASSWORD}")"
                            cat > dynamic_admin.auto.tfvars.json <<EOF
{
  "enable_ssh_key": false,
  "admin_user": {
    "enabled": true,
    "username": "${SERVER_ADMIN_USERNAME}",
    "password_hash": "${SERVER_ADMIN_PASSWORD_HASH}"
  }
}
EOF
                            terraform init
                            terraform plan -no-color | tee plan_output.txt
                        '''
                        env.TF_SUMMARY = sh(script: "grep 'Plan:' plan_output.txt || echo 'No changes detected'", returnStdout: true).trim()
                    }
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'server_admin_login', usernameVariable: 'SERVER_ADMIN_USERNAME', passwordVariable: 'SERVER_ADMIN_PASSWORD')
                ]) {
                    sh '''
                        if ! command -v openssl >/dev/null 2>&1; then
                          if command -v apk >/dev/null 2>&1; then
                            apk add --no-cache openssl
                          elif command -v apt-get >/dev/null 2>&1; then
                            apt-get update && apt-get install -y openssl
                          else
                            echo "Cannot install openssl in this build container."
                            exit 1
                          fi
                        fi

                        SERVER_ADMIN_PASSWORD_HASH="$(openssl passwd -6 "${SERVER_ADMIN_PASSWORD}")"
                        cat > dynamic_admin.auto.tfvars.json <<EOF
{
  "enable_ssh_key": false,
  "admin_user": {
    "enabled": true,
    "username": "${SERVER_ADMIN_USERNAME}",
    "password_hash": "${SERVER_ADMIN_PASSWORD_HASH}"
  }
}
EOF
                        terraform apply -auto-approve
                    '''
                }
            }
        }
        stage('Post-Provision Configure Servers') {
            when {
                expression { return params.RUN_POST_PROVISION }
            }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'server_admin_login', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASSWORD'),
                    string(credentialsId: 'NETBIRD_SETUP_KEY', variable: 'NETBIRD_SETUP_KEY'),
                    string(credentialsId: 'TENABLE_KEY', variable: 'TENABLE_KEY')
                ]) {
                    sh '''
                        terraform output -raw server_public_ips_csv > server_ips.txt || true
                        SERVER_IPS="$(cat server_ips.txt)"
                        if [ -z "$SERVER_IPS" ]; then
                          echo "No server IPs found from Terraform output. Skipping post-provision."
                          exit 0
                        fi

                        if ! command -v ssh >/dev/null 2>&1 || ! command -v scp >/dev/null 2>&1 || ! command -v sshpass >/dev/null 2>&1; then
                          if command -v apk >/dev/null 2>&1; then
                            apk add --no-cache openssh-client sshpass
                          elif command -v apt-get >/dev/null 2>&1; then
                            apt-get update && apt-get install -y openssh-client sshpass
                          else
                            echo "Cannot install ssh/scp/sshpass client tools in this build container."
                            exit 1
                          fi
                        fi

                        OLD_IFS="$IFS"
                        IFS=','
                        for HOST in $SERVER_IPS; do
                          HOST="$(echo "$HOST" | xargs)"
                          if [ -z "$HOST" ]; then
                            continue
                          fi

                          echo "Waiting for SSH on $HOST ..."
                          ATTEMPT=1
                          SSH_ERR_FILE="$(mktemp)"
                          until sshpass -p "$SSH_PASSWORD" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 "$SSH_USER@$HOST" "echo SSH_READY" >/dev/null 2>"$SSH_ERR_FILE"; do
                            if [ "$ATTEMPT" -eq 1 ]; then
                              echo "First SSH error for $HOST:"
                              sed -n '1,5p' "$SSH_ERR_FILE" || true
                            fi
                            if [ "$ATTEMPT" -ge 30 ]; then
                              echo "SSH not reachable on $HOST after multiple attempts."
                              echo "Last SSH error for $HOST:"
                              cat "$SSH_ERR_FILE" || true
                              rm -f "$SSH_ERR_FILE"
                              exit 1
                            fi
                            ATTEMPT=$((ATTEMPT + 1))
                            sleep 10
                          done
                          rm -f "$SSH_ERR_FILE"

                          sshpass -p "$SSH_PASSWORD" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$HOST" "rm -rf /tmp/hetzner-ops && mkdir -p /tmp/hetzner-ops"
                          sshpass -p "$SSH_PASSWORD" scp -o PreferredAuthentications=password -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scripts/ops/*.sh "$SSH_USER@$HOST:/tmp/hetzner-ops/"

                          sshpass -p "$SSH_PASSWORD" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$HOST" "
                            sudo mkdir -p /opt/hetzner-ops
                            sudo cp /tmp/hetzner-ops/*.sh /opt/hetzner-ops/
                            sudo chmod +x /opt/hetzner-ops/*.sh
                            sudo RUN_CREATE_USER=false \
                              RUN_AZURE_AGENT=${RUN_AZURE_AGENT} \
                              RUN_ZABBIX=${RUN_ZABBIX} \
                              RUN_NETBIRD=${RUN_NETBIRD} \
                              RUN_WAZUH=${RUN_WAZUH} \
                              RUN_TENABLE=${RUN_TENABLE} \
                              RUN_HARDENING=${RUN_HARDENING} \
                              NETBIRD_SETUP_KEY='${NETBIRD_SETUP_KEY}' \
                              TENABLE_KEY='${TENABLE_KEY}' \
                              /opt/hetzner-ops/run_post_provision.sh
                          "
                        done
                        IFS="$OLD_IFS"
                    '''
                }
            }
        }
        stage('Publish Inventory to Google Sheet') {
            steps {
                sh '''
                    if ! command -v curl >/dev/null 2>&1; then
                      if command -v apk >/dev/null 2>&1; then
                        apk add --no-cache curl
                      elif command -v apt-get >/dev/null 2>&1; then
                        apt-get update && apt-get install -y curl
                      else
                        echo "Cannot install curl in this build container."
                        exit 1
                      fi
                    fi

                    terraform output -json inventory_servers > inventory_servers.json || echo '[]' > inventory_servers.json
                    SERVERS_JSON=$(cat inventory_servers.json)
                    cat > inventory_payload.json <<EOF
{"servers": ${SERVERS_JSON}}
EOF
                    curl -fsS -X POST "$GOOGLE_SHEET_WEBHOOK_URL" \
                      -H "Content-Type: application/json" \
                      --data @inventory_payload.json
                '''
            }
        }
    }

    post {
        always {
            // PERMANENT FIX: Delete root-owned files before the container exits
            // This allows the next 'Git Checkout' to succeed
            sh 'rm -rf .terraform*' 
            sh 'rm -f plan_output.txt inventory_servers.json inventory_payload.json server_ips.txt dynamic_admin.auto.tfvars.json'
            cleanWs()
        }
        success {
            slackSend(channel: 'C0ACD830SBC', color: 'good', 
                message: "✅ *Hetzner Deployment Successful*\n*Build:* #${env.BUILD_NUMBER}\n*Status:* ${env.TF_SUMMARY}\n*Link:* ${env.BUILD_URL}")
        }
        failure {
            slackSend(channel: 'C0ACD830SBC', color: 'danger', 
                message: "❌ *Hetzner Deployment Failed*\n*Build:* #${env.BUILD_NUMBER}\n*Error:* Check logs immediately: ${env.BUILD_URL}")
        }
    }
}
