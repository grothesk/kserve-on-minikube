# kserve-on-docker-desktop

How to install and test KServe on Docker-Desktop.
Use this setup if you are on a mac with apple silicon.

## Requirements

The following components were used for this setup:
* Docker-Desktop (v4.26.1, make sure to enable rosetta)
* Kubernetes (v1.28.2)
* Istio (v1.20.3)
* KNative (v1.31.1)
* KServe(v0.11.0)
* mc - MinIO Client (RELEASE.2024-03-09T06-43-06Z)
* hey

## Install prerequisits

Kserve builds upon Istio and Knative, with the respective configurations and certificates.
In this simplified setup all of this can be deployed as follows.
```bash
make install-knative-serving
make install-istio
make integrate-istio-knative
make configure-mtls
make configure-dns
make verify-instio-installation
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
make deploy-inference-service
```

5. Test the InferenceService:
```bash
make infer
```

Create some load in another shell and watch pods starting and terminating:
```bash
make infer-concurrent
```
