#!/bin/bash

#set -e

source ./values.sh

configure_interfaces(){
    i=1
    for namespace in "${values_network_namespaces[@]}"
    do
        local nn_if_name="eth0-$namespace"
        local ovs_if_name="veth-$namespace"

        ip link set up dev "$ovs_if_name"
        ip netns exec "$namespace" ip link set up dev lo
        ip netns exec "$namespace" ip link set up dev "$nn_if_name"

        ip netns exec "$namespace" ip address add "10.0.123.$i/24" dev "$nn_if_name"
        i=$((i+1))
    done
}