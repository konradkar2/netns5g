#!/bin/bash

#set -e

source ./values.sh
source ./delete_interfaces.sh

delete_namespaces(){
    for nn in "${values_network_namespaces[@]}"
    do
        ip netns del "$nn"
    done
}

delete_interfaces
delete_namespaces
delete_ovs_switch