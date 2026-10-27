# Part 3: FOCUS queries across providers, and Cloud Custodian.
state_focus
cap p03-top-services 'duckdb focus.duckdb -f focus/top-services.sql'

cap p03-c7n-version 'custodian version'
cap p03-c7n-validate 'custodian validate custodian/cost.yml'

# A local moto server stands in for AWS, with a few test resources.
must 'moto_server -p 5000 > moto.log 2>&1 &'
must 'for i in $(seq 1 30); do curl -s -o /dev/null http://127.0.0.1:5000 && break; sleep 1; done'
export AWS_ENDPOINT_URL=http://127.0.0.1:5000 AWS_ACCESS_KEY_ID=testing AWS_SECRET_ACCESS_KEY=testing AWS_DEFAULT_REGION=us-east-1
must 'c7n-python custodian/seed-moto.py'

cap p03-c7n-run 'custodian run --dryrun -s out custodian/cost.yml'
cap p03-c7n-report 'custodian report -s out custodian/cost.yml -p ebs-unattached --format grid'
cap p03-c7n-report-eip 'custodian report -s out custodian/cost.yml -p eip-unassociated --format grid'
