# Part 3: OpenCost on a local kind cluster.
must 'kind create cluster --config opencost/kind.yaml --wait 180s'
must 'kubectl wait --for=condition=Ready nodes --all --timeout=180s'

cap p03k-repo 'helm repo add opencost https://opencost.github.io/opencost-helm-chart'
cap p03k-install 'helm install opencost opencost/opencost --version 2.5.33 --namespace opencost --create-namespace --values opencost/values.yaml --wait --timeout 5m'
cap p03k-workloads 'kubectl apply -f opencost/workloads.yaml'
must 'kubectl -n checkout rollout status deployment/checkout-api --timeout=180s'
must 'kubectl -n reports rollout status deployment/report-builder --timeout=180s'
cap p03k-pods 'kubectl get pods -n opencost'

cap p03k-pf 'kubectl -n opencost port-forward service/opencost 9003:9003 > /dev/null 2>&1 &'
must 'for i in $(seq 1 60); do curl -s -o /dev/null http://localhost:9003/healthz && break; sleep 2; done'

# The collector needs a while before the first allocation data appears;
# wait for it, then let 20 more minutes of data accumulate.
must 'for i in $(seq 1 60); do curl -s "http://localhost:9003/allocation?window=1h&aggregate=namespace" | jq -e ".data[0] | length > 0" > /dev/null && break; sleep 60; done'
must 'sleep 1200'
cap p03k-allocation "curl -s 'http://localhost:9003/allocation?window=1h&aggregate=namespace&accumulate=true' | jq -r '[\"NAMESPACE\", \"MINUTES\", \"CPU_REQ\", \"CPU_USED\", \"RAM_REQ_MIB\", \"RAM_USED_MIB\", \"COST_USD\"], (.data[0][] | [.name, .minutes, .cpuCoreRequestAverage, (.cpuCoreUsageAverage * 1000 | round / 1000), (.ramByteRequestAverage / 1048576 | round), (.ramByteUsageAverage / 1048576 | round), .totalCost]) | @tsv' | column -t"
cap p03k-raw "curl -s 'http://localhost:9003/allocation?window=1h&aggregate=namespace&accumulate=true'"
