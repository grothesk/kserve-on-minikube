#!/bin/bash
echo "$(cat minio_ip) minio.${CLUSTER_NAME}.minikube" >> /etc/hosts
