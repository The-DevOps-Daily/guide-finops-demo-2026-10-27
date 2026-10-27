# Part 4: tags, budgets and anomaly alerts as Terraform code.
tf_mock
cap p04-cd 'cd infra'
cap p04-version 'terraform version'
cap p04-init 'terraform init'
cap p04-validate 'terraform validate'
cap p04-missing-owner 'terraform plan -var-file=env/dev.tfvars -var owner=payments'
cap p04-plan-dev 'terraform plan -var-file=env/dev.tfvars -out=dev.tfplan'
cap p04-tags "terraform show -json dev.tfplan | jq '.resource_changes[] | select(.address == \"aws_launch_template.app\") | .change.after.tag_specifications'"
cap p04-size-dev "echo 'local.size' | terraform console -var-file=env/dev.tfvars"
cap p04-size-prod "echo 'local.size' | terraform console -var-file=env/prod.tfvars"
cap p04-cd-back 'cd ..'

must 'terraform -chdir=multicloud/azure init -input=false > /dev/null'
must 'terraform -chdir=multicloud/google init -input=false > /dev/null'
cap p04-azure-validate 'terraform -chdir=multicloud/azure validate'
cap p04-google-validate 'terraform -chdir=multicloud/google validate'
