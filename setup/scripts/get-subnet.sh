#!/bin/bash
network_name=mk-${CLUSTER_NAME}

get_bridge() {
    bridge_value=$(virsh net-info $network_name | grep "Bridge" | awk '{print $2}')
}

get_subnet() {
    ip_range=$(ip addr show dev $bridge_value | grep "inet " | awk '{print $2}')
    echo "Subnet for $bridge_value: $ip_range"
}

get_bridge
get_subnet
