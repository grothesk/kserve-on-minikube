#!/bin/sh

PODS=$(kubectl get pods --selector=app.kubernetes.io/instance=cert-manager -n cert-manager -o custom-columns=NAME:metadata.name --no-headers)

for POD in $PODS
do
  kubectl wait --for=condition=Ready pod/$POD -n cert-manager
done
