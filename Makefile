CLUSTER_NAME ?= ksurf
CLUSTER_CPU ?= 10
CLUSTER_MEMORY ?= 12g
CLUSTER_DISK_SIZE ?= 40g

KNATIVE_VERSION := v1.13.1
ISTIO_VERSION := 1.20.3
CERT_MANAGER_VERSION := v1.14.3
KSERVE_VERSION := v0.11.0


.PHONY: install-knative-serving
install-knative-serving:
	URL=https://github.com/knative/serving/releases/download/knative-${KNATIVE_VERSION}/serving-crds.yaml \
	FILE=serving-crds.yaml TARGET_DIR=deploy/knative-serving scripts/get-and-apply.sh 

	URL=https://github.com/knative/serving/releases/download/knative-${KNATIVE_VERSION}/serving-core.yaml \
	FILE=serving-core.yaml TARGET_DIR=deploy/knative-serving scripts/get-and-apply.sh 

.PHONY: install-istio
install-istio:
	curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -
	istio-${ISTIO_VERSION}/bin/istioctl manifest generate > deploy/istio/generated-manifest.yaml
	istio-${ISTIO_VERSION}/bin/istioctl install -y

.PHONY: integrate-istio-knative
integrate-istio-knative:
	URL=https://github.com/knative/net-istio/releases/download/knative-${KNATIVE_VERSION}/net-istio.yaml \
	FILE=net-istio.yaml TARGET_DIR=deploy/istio scripts/get-and-apply.sh

.PHONY: configure-mtls
configure-mtls:
	kubectl label namespace knative-serving istio-injection=enabled
	kubectl apply -f deploy/istio/peer-authentication.yaml

.PHONY: configure-dns 
configure-dns:
	kubectl patch configmap/config-domain \
  	--namespace knative-serving \
  	--type merge \
  	--patch '{"data":{"${CLUSTER_NAME}.minikube":""}}'

.PHONY: verify-instio-installation
verify-istio-installation:
	istio-${ISTIO_VERSION}/bin/istioctl verify-install

.PHONY: install-cert-manager
install-cert-manager:
	URL=https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml \
	FILE=cert-manager.yaml TARGET_DIR=deploy/cert-manager scripts/get-and-apply.sh

.PHONY: install-kserve
install-kserve:
	URL=https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve.yaml \
	FILE=kserve.yaml TARGET_DIR=deploy/kserve scripts/get-and-apply.sh

.PHONY: install-runtimes
install-runtimes:
	URL=https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve-runtimes.yaml \
	FILE=kserve-runtimes.yaml TARGET_DIR=deploy/kserve scripts/get-and-apply.sh

.PHONY: install-minio
install-minio:
	kubectl apply -k deploy/minio

.PHONY: create-model-bucket
create-model-bucket:
	mc config host add model-storage http://localhost:9000 minio minio123
	mc mb model-storage/models/sklearn/iris/1.0/models

.PHONY: upload-model
upload-model:
	mc cp models/sklearn/iris/1.0/models/model.joblib model-storage/models/sklearn/iris/1.0/models/model.joblib

.PHONY: deploy-inference-service
deploy-inference-service:
	kubectl apply -k deploy/inference-service-examples/sklearn-s3

.PHONY: infer
infer:
	scripts/infer-iris.sh

.PHONY: infer-concurrent
infer-concurrent:
	scripts/infer-iris-concurrent.sh