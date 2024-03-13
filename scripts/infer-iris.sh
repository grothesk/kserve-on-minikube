#!/bin/bash

curl -XPOST http://sklearn-iris-predictor.examples.ksurf.minikube/v2/models/sklearn-iris/infer \
     -H 'accept: application/json' \
     -H 'Content-Type: application/json' \
     --data @data/iris-input.json