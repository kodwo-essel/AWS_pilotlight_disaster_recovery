pipeline {
    agent any

    parameters {
        // Parameter to control whether to destroy infrastructure
        booleanParam(name: 'destroy', defaultValue: false, description: 'Set to true to destroy the infrastructure')
    }

    environment {
        STATE_FILE_ID = "pilot-light-full-infrastructure-vars"  // ID for your Terraform state file credentials
    }

    stages {
        stage('Checkout Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/kodwo-essel/AWS_pilotlight_disaster_recovery.git'
            }
        }

        stage('Inject terraform.tfvars') {
            steps {
                withCredentials([file(credentialsId: "${STATE_FILE_ID}", variable: 'TFVARS_FILE')]) {
                    // Inject the terraform.tfvars file
                    sh "cp -f \"${TFVARS_FILE}\" terraform.tfvars"
                    echo 'terraform.tfvars injected.'

                }
                
            }
        }

        stage('Terraform Init') {
            steps {
                
                withCredentials([aws(credentialsId: "aws-credentials")]) {
                    // Initialize Terraform with AWS credentials
                    sh 'terraform init'
                }
                
            }
        }

        stage('Terraform Plan') {
            steps {
                
                withCredentials([aws(credentialsId: "aws-credentials")]) {
                    // Run Terraform plan with AWS credentials
                    sh 'terraform plan -out=tfplan'
                }
                
            }
        }

        // Conditional stage based on destroy parameter
        stage('Terraform Apply') {
            when {
                expression { return !params.destroy }
            }
            steps {

                withCredentials([aws(credentialsId: "aws-credentials")]) {
                    input message: 'Approve Terraform Apply?', ok: 'Apply'
                    // Apply the Terraform plan
                    sh 'terraform apply -auto-approve tfplan'
                }
            
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return params.destroy }
            }
            steps {

                withCredentials([aws(credentialsId: "aws-credentials")]) {
                    input message: 'Are you sure you want to destroy the infrastructure?', ok: 'Destroy'
                    // Destroy the infrastructure
                    sh 'terraform destroy -auto-approve'
                }
                
            }
        }
    }

    post {
        success {
            echo 'Terraform operation completed successfully.'
        }
        failure {
            echo 'Terraform operation failed.'
        }
        always {
            cleanWs()  // Clean up the workspace after the run
        }
    }
}
