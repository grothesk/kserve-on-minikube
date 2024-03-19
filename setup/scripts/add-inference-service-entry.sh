#!/bin/bash
echo "$(cat sklearn_s3_ip) sklearn-iris-predictor.examples.${CLUSTER_NAME}.minikube" >> /etc/hosts
