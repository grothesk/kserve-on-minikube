#!/bin/sh

NODE_IP="$(kubectl get nodes -o 'custom-columns=THIS:.status.addresses[?(@.type=="InternalIP")].address' --no-headers)" && test -n $NODE_IP &&
echo "Node IP is: $NODE_IP"
