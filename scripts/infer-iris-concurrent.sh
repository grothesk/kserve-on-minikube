#!/bin/bash

hey -z 60s -c 500 -m POST -H 'accept: application/json' -D data/iris-input.json -T application/json http://sklearn-iris-predictor.examples.ksurf.minikube/v2/models/sklearn-iris/infer
