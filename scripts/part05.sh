# Part 5: policy checks on the plan, as the cost-checks workflow runs them.
tf_mock
cap p05-cd 'cd infra'
must 'terraform init -input=false > /dev/null'
cap p05-plan 'terraform plan -var-file=env/dev.tfvars -out=tfplan > /dev/null && terraform show -json tfplan > plan.json'
cap p05-conftest-pass 'conftest test plan.json --policy ../policy'
cap p05-plan-big 'terraform plan -var-file=env/dev.tfvars -var instance_type=m7i.2xlarge -out=tfplan > /dev/null && terraform show -json tfplan > plan.json'
cap p05-conftest-fail 'conftest test plan.json --policy ../policy'
cap p05-cd-back 'cd ..'
cap p05-actionlint 'actionlint .github/workflows/cost-checks.yml .github/workflows/infracost.yml .github/workflows/preview-cleanup.yml'
