#!/bin/bash

#set -e

move_if_to_namespace(){
    local interface=$1
    local namespace=$2

    ip link set $interface netns $namespace
}

attach_if_to_switch(){
    local interface=$1

    ovs-vsctl add-port $values_switch_name $interface
}


create_interface(){
    local if_local="$1"
    local if_ovs="$2"
    local namespace="$3"

    ip link add $if_local type veth peer name $if_ovs
    if [ "$namespace" != "root" ]
    then
        move_if_to_namespace $if_local $namespace
    fi
    attach_if_to_switch $if_ovs
}

configure_interface(){
    local if_local="$1"
    local if_ovs="$2"
    local namespace="$3"
    local address="$4"

    local cidr=$(yq -e ".predeployment.network.cidr"  values.yaml)

    ip link set up dev "$if_ovs"
    ip netns exec "$namespace" ip link set up dev lo
    ip netns exec "$namespace" ip link set up dev "$if_local"

    ip netns exec "$namespace" ip address add "$address"/"$cidr" dev "$if_local"
}


create_interfaces(){
    services_length=$(yq -e ".predeployment.services | length"  values.yaml)
    for (( service_idx=0; service_idx<$services_length; service_idx++ ))
    do
        local service_name=$(yq -e ".predeployment.services["$service_idx"].name" values.yaml)
        local namespace=$(yq -e ".predeployment.services["$service_idx"].namespace" values.yaml)

        intefaces_length=$(yq -e ".predeployment.services["$service_idx"].interfaces | length"  values.yaml)
        for (( if_idx=0; if_idx<$intefaces_length; if_idx++ ))
        do
            local if_name=$(yq -e ".predeployment.services["$service_idx"].interfaces["$if_idx"]" values.yaml)
            echo -e "Creating interface: $service_name $if_name"

            if_ovs="veth-$namespace-$if_name"
            create_interface $if_name $if_ovs $namespace

            address=$(yq -e ".predeployment.services["$service_idx"].interfaces["$if_idx"].address" values.yaml)
            configure_interface $if_name $if_ovs $namespace $address
        done
    done
}

create_interfaces