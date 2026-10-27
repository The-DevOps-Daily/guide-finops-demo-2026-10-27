# FinOps for DevOps Engineers: companion repository

The code for the [FinOps for DevOps Engineers](https://devops-daily.com/guides/finops-for-devops-engineers) guide on DevOps Daily. The running example is `checkout`, a service owned by the `payments` team, on AWS in `us-east-1` with `dev`, `staging` and `prod` environments.

| Path | What it is | Part |
| --- | --- | --- |
| `focus/` | DuckDB queries over the FOCUS sample billing data | 1, 2, 3, 6, 7 |
| `custodian/` | Cloud Custodian policies for idle resources and missing owners | 3 |
| `opencost/` | OpenCost on a local kind cluster, with two example workloads | 3 |
| `infra/` | Terraform for the service: tags, sizes per environment, office-hours schedule, budget and anomaly alert | 4, 5 |
| `multicloud/` | The same budget for Azure and Google Cloud | 4 |
| `policy/` | Conftest (OPA) cost policy for Terraform plans | 5 |
| `.github/workflows/cost-checks.yml` | Plans every environment and checks the plan against the policy | 5 |
| `.github/workflows/infracost.yml` | Infracost cost diff on pull requests | 5 |

## How the guide's output was made

`.github/workflows/guide.yml` runs the commands of each part on a GitHub-hosted runner with `scripts/partNN.sh` and keeps each command's output as an artifact. The guide shows that output. Nothing talks to a real cloud account:

- `terraform plan` runs with mock credentials (`ci/mock_provider_override.tf`), which works because the configuration reads nothing from AWS.
- Cloud Custodian runs against [moto](https://github.com/getmoto/moto), a local AWS emulator, with a few test resources from `custodian/seed-moto.py`.
- The billing data is the anonymized [FOCUS 1.0 sample](https://github.com/FinOps-Open-Cost-and-Usage-Spec/FOCUS-Sample-Data) from the FinOps Foundation (CC BY 4.0).

`cost-checks.yml` and `infracost.yml` are switched off here (they need an AWS role and an Infracost token); set the repository variables named in each file to turn them on in your own copy.
