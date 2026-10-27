# Part 3: OpenCost on a local kind cluster.
must 'kind create cluster --config opencost/kind.yaml --wait 180s'
must 'kubectl wait --for=condition=Ready nodes --all --timeout=180s'

cap p03k-repo 'helm repo add opencost https://opencost.github.io/opencost-helm-chart'
cap p03k-install 'helm install opencost opencost/opencost --version 2.5.33 --namespace opencost --create-namespace --values opencost/values.yaml --wait --timeout 5m'
cap p03k-workloads 'kubectl apply -f opencost/workloads.yaml'
must 'kubectl -n checkout rollout status deployment/checkout-api --timeout=180s'
must 'kubectl -n reports rollout status deployment/report-builder --timeout=180s'
cap p03k-pods 'kubectl get pods -n opencost'

must 'kubectl -n opencost port-forward service/opencost 9003:9003 > pf.log 2>&1 &'
must 'for i in $(seq 1 60); do curl -s -o /dev/null http://localhost:9003/healthz && break; sleep 2; done'

# Exploration: the raw API response as data accumulates.
for t in 5 10 15 20 25 30; do
  must 'sleep 300'
  cap "p03k-raw-$t" "curl -s 'http://localhost:9003/allocation?window=30m&aggregate=namespace&accumulate=true'"
done
cap p03k-raw-compute "curl -s 'http://localhost:9003/allocation/compute?window=30m&aggregate=namespace&accumulate=true'"
