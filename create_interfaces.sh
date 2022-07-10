#!/bin/bash

#set -e

source ./values.sh

move_if_to_namespace(){
    local interface=$1
    local namespace=$2

    ip link set $interface netns $namespace
}

attach_if_to_switch(){
    local interface=$1

    ovs-vsctl add-port $values_switch_name $interface
}

#to access servers from host e.g. free5gc's webui
create_if_host(){
    local if_host=$1
    local if_ovs=$2

    ip link add $if_host type veth peer name $if_ovs
}

create_interfaces(){
    for namespace in "${values_network_namespaces[@]}"
    do
        local nn_if_name="eth0-$namespace"
        local ovs_if_name="veth-$namespace"

        ip link add $nn_if_name type veth peer name $ovs_if_name
        move_if_to_namespace $nn_if_name $namespace
        attach_if_to_switch $ovs_if_name
    done

    create_if_host "eth0-host" "veth-host"
    attach_if_to_switch "veth-host"
}
