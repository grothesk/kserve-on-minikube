#!/bin/bash

model_name="$1" && test -n "$model_name" &&
ip=$(kubectl -n istio-system get svc istio-ingressgateway -o json | jq -r .status.loadBalancer.ingress[0].ip) && test -n "$ip" &&
entry="${ip} ${model_name}-predictor.model.${CLUSTER_NAME}.minikube" &&
grep "$entry" /etc/hosts || sudo sh -c 'echo '"$entry"' >> /etc/hosts'
