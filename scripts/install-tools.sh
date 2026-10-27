#!/usr/bin/env bash
# Installs the pinned tools the guide uses on a GitHub-hosted Ubuntu runner (amd64).
set -euo pipefail
BIN=/usr/local/bin
TMP=$(mktemp -d)
cd "$TMP"

need() { [ " ${TOOLS:-all} " = " all " ] || [[ " $TOOLS " == *" $1 "* ]]; }

if need terraform; then
  curl -fsSLO https://releases.hashicorp.com/terraform/1.17.0/terraform_1.17.0_linux_amd64.zip
  curl -fsSLO https://releases.hashicorp.com/terraform/1.17.0/terraform_1.17.0_SHA256SUMS
  grep ' terraform_1.17.0_linux_amd64.zip$' terraform_1.17.0_SHA256SUMS | sha256sum -c
  unzip -q terraform_1.17.0_linux_amd64.zip terraform
  sudo install -m 0755 terraform "$BIN/terraform"
fi

if need conftest; then
  curl -fsSLO https://github.com/open-policy-agent/conftest/releases/download/v0.71.1/conftest_0.71.1_Linux_x86_64.tar.gz
  curl -fsSLO https://github.com/open-policy-agent/conftest/releases/download/v0.71.1/checksums.txt
  grep ' conftest_0.71.1_Linux_x86_64.tar.gz$' checksums.txt | sha256sum -c
  tar -xzf conftest_0.71.1_Linux_x86_64.tar.gz conftest
  sudo install -m 0755 conftest "$BIN/conftest"
fi

if need duckdb; then
  curl -fsSLO https://github.com/duckdb/duckdb/releases/download/v2.0.0/duckdb-cli-linux-amd64.tar.gz
  tar -xzf duckdb-cli-linux-amd64.tar.gz
  sudo install -m 0755 duckdb "$BIN/duckdb"
fi

if need actionlint; then
  curl -fsSLO https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_linux_amd64.tar.gz
  curl -fsSLO https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_checksums.txt
  grep ' actionlint_1.7.12_linux_amd64.tar.gz$' actionlint_1.7.12_checksums.txt | sha256sum -c
  tar -xzf actionlint_1.7.12_linux_amd64.tar.gz actionlint
  sudo install -m 0755 actionlint "$BIN/actionlint"
fi

if need custodian; then
  python3 -m venv /opt/c7n
  /opt/c7n/bin/pip install --quiet c7n==0.9.53.0 'moto[server]==5.2.4'
  sudo ln -sf /opt/c7n/bin/custodian "$BIN/custodian"
  sudo ln -sf /opt/c7n/bin/moto_server "$BIN/moto_server"
  sudo ln -sf /opt/c7n/bin/python "$BIN/c7n-python"
fi

if need kind; then
  curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-amd64
  curl -fsSLo kind.sha256 https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-amd64.sha256sum
  echo "$(cut -d' ' -f1 kind.sha256)  kind" | sha256sum -c
  sudo install -m 0755 kind "$BIN/kind"
  curl -fsSLO https://dl.k8s.io/release/v1.37.1/bin/linux/amd64/kubectl
  curl -fsSLO https://dl.k8s.io/release/v1.37.1/bin/linux/amd64/kubectl.sha256
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c
  sudo install -m 0755 kubectl "$BIN/kubectl"
  curl -fsSLO https://get.helm.sh/helm-v4.3.1-linux-amd64.tar.gz
  curl -fsSLO https://get.helm.sh/helm-v4.3.1-linux-amd64.tar.gz.sha256sum
  sha256sum -c helm-v4.3.1-linux-amd64.tar.gz.sha256sum
  tar -xzf helm-v4.3.1-linux-amd64.tar.gz linux-amd64/helm
  sudo install -m 0755 linux-amd64/helm "$BIN/helm"
fi
