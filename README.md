# kserve-on-minikube

How to install KServe on Minikube

## Requirements

The following components were used for this setup:
* minikube (v1.32.0)
* Kubernetes (v1.27.4)
* Istio (v1.20.3)
* KNative (v1.31.1)
* KServe(v0.11.0)
* mc - MinIO Client (RELEASE.2024-02-24T01-33-20Z)
* hey

## Create cluster

Create the minikube cluster like this:
```bash
make create-cluster
```

## Enable Add-ons

Enable the required minikube add-ons:
```bash
make enable-addons
```

This activates the following add-ons:
* ingress
* ingress-dns ([https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/](https://minikube.sigs.k8s.io/docs/handbook/addons/ingress-dns/))
* metallb

## Configure MetalLB

In order to set up MetalLB, perform the following steps:
1. Determine the virtual bridge that belongs to the node of your minikube cluster.
2. Determine the subnet associated with the virtual bridge.
3. Add a suitable IP range within the subnet to the default address pool:
```bash
make configure-lb
```

### Sources

* [https://kubebyexample.com/learning-paths/metallb/install](https://kubebyexample.com/learning-paths/metallb/install)

## Install Knative-Serving

Install Knative-Serving like this:
```bash
make install-knative-serving
```

## Install Istio

Install and integrate Istio like this:
```bash
make install-istio integrate-istio-knative configure-mtls configure-dns verify-instio-installation  
```

### Sources
* [https://knative.dev/docs/install/installing-istio/](https://knative.dev/docs/install/installing-istio/)

## Install Cert-Manager

Install Cert-Manager like this:
```bash
make install-cert-manager
```

## Install KServe

Install KServe like this:
```bash
make install-kserve
```

Install the built-in ClusterServingRuntimes like this:
```bash
make install-runtimes
```

## Install MinIO

Install MinIO like this:
```bash
make install-minio
```

Optional: create an entry in your /etc/hosts, so that you can access your minio cluster using a DNS name instead of using its IP address:
```bash
make add-minio-entry
```

## Running the sklearn-s3 example

0. Make sure, mc and hey have been installed. You may have a look here [https://github.com/minio/mc](https://github.com/minio/mc) and here [https://github.com/rakyll/hey](https://github.com/rakyll/hey)

1. Create a bucket for your model on MinIO:
```bash
make create-model-bucket
```

2. Upload the model to your minio cluster:
```bash
make upload-model
```

3. Deploy the InferenceService like this:
```bash
kubectl apply -k deploy/inference-service-examples/sklearn-s3
```

4. Create an entry in your `/etc/hosts`, so your client can make use of the ingress gateway by calling the FQDN of your InferenceService:
```bash
make add-inference-service-entry
```

5. Test the InferenceService:
```bash
make infer
```

6. Test scaling of the InferenceService like this:
```bash
make watch-inference-pods
```

Create some load in another shell and watch pods starting and terminating:
```bash
make infer-concurrent
```
