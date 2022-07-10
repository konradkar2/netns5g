#!/bin/bash

#set -e

source ./values.sh

delete_ovs_switch(){
    ovs-vsctl del-br "$values_switch_name"
}

delete_if_from_switch(){
    local interface=$1

    ovs-vsctl del-port "$values_switch_name" "$interface"
}


delete_interfaces(){
    for namespace in "${values_network_namespaces[@]}"
    do
        local nn_if_name="eth0-$namespace"
        local ovs_if_name="veth-$namespace"

        delete_if_from_switch "$ovs_if_name"

        ip link del dev "$ovs_if_name"
    done

    delete_if_from_switch "veth-host"
    ip link del dev "eth0-host"
}

