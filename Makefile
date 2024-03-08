CLUSTER_NAME ?= ksurf
CLUSTER_CPU ?= 10
CLUSTER_MEMORY ?= 12g
CLUSTER_DISK_SIZE ?= 40g
CLUSTER_DRIVER ?= docker

KNATIVE_VERSION := v1.13.1
ISTIO_VERSION := 1.20.3
CERT_MANAGER_VERSION := v1.14.3
KSERVE_VERSION := v0.11.0

MINIO_CLIENT_BIN ?= mc

.PHONY: create-cluster
create-cluster:
	minikube -p ${CLUSTER_NAME} start --cpus=${CLUSTER_CPU} --memory=${CLUSTER_MEMORY} --disk-size=${CLUSTER_DISK_SIZE} --driver=${CLUSTER_DRIVER}

.PHONY: enable-addons
enable-addons:
	minikube -p ${CLUSTER_NAME} addons enable ingress
	minikube -p ${CLUSTER_NAME} addons enable ingress-dns
	minikube -p ${CLUSTER_NAME} addons enable metallb

.PHONY: get-subnet
get-subnet:
	sudo CLUSTER_NAME=${CLUSTER_NAME} scripts/get-subnet.sh

.PHONY: configure-lb 
configure-lb:
	minikube -p ${CLUSTER_NAME} addons configure metallb 

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

.PHONY: verify-istio-installation
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

.PHONY: add-minio-entry
add-minio-entry:
	kubectl -n model-storage get svc minio -o json | jq -r .status.loadBalancer.ingress[0].ip > minio_ip
	sudo CLUSTER_NAME=${CLUSTER_NAME} scripts/add-minio-entry.sh
	rm minio_ip

.PHONY: create-model-bucket
create-model-bucket:
	${MINIO_CLIENT_BIN} config host add model-storage http://minio.${CLUSTER_NAME}.minikube:9000 minio minio123
	${MINIO_CLIENT_BIN} mb model-storage/models/sklearn/iris/1.0/models

.PHONY: upload-model
upload-model:
	${MINIO_CLIENT_BIN} cp models/sklearn/iris/1.0/models/model.joblib model-storage/models/sklearn/iris/1.0/models

.PHONY: add-inference-service-entry
add-inference-service-entry:
	kubectl -n istio-system get svc istio-ingressgateway -o json | jq -r .status.loadBalancer.ingress[0].ip > sklearn_s3_ip
	sudo CLUSTER_NAME=${CLUSTER_NAME} scripts/add-inference-service-entry.sh
	rm sklearn_s3_ip

.PHONY: infer
infer:
	curl -X POST http://sklearn-iris-predictor.examples.${CLUSTER_NAME}.minikube/v2/models/sklearn-iris/infer \
    -H 'accept: application/json' -H 'Content-Type: application/json' \
    --data @data/iris-input.json | jq

.PHONY: watch-inference-pods
watch-inference-pods:
	kubectl -n examples get po -w

.PHONY: infer-concurrent
infer-concurrent:
	./hey -z 30s -c 300 -m POST -D data/iris-input.json http://sklearn-iris-predictor.examples.${CLUSTER_NAME}.minikube/v2/models/sklearn-iris/infer