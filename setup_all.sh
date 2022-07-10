#!/bin/bash

source ./create_interfaces.sh
source ./configure_interfaces.sh
source ./values.sh

create_namespaces(){
    for nn in "${values_network_namespaces[@]}"
    do
        ip netns add "$nn"
    done
}

create_ovs_switch(){
    ovs-vsctl add-br $values_switch_name
}

create_namespaces
create_ovs_switch
create_interfaces
configure_interfaces