#!/bin/bash

source ./values.sh

PID_LIST=()

function terminate()
{
    echo "Receive SIGINT, terminating..."
    for ((i=${#PID_LIST[@]}-1;i>=0;i--)); do
        sudo kill -SIGTERM ${PID_LIST[i]}
    done
    sleep 2
    wait ${PID_LIST}
    exit 0
}
trap terminate SIGINT

deploy_mongodb(){
    local namespace=$1

    ip netns exec $namespace $values_mongdod_binary_path --config $values_mongdod_config_path &
    PID_LIST+=($!)
}
deploy_nf(){
    local namespace=$1

    ip netns exec $namespace $values --config $values_mongdod_config_path &
    PID_LIST+=($!)
}


deploy_processes(){
    for nn in "${values_network_namespaces[@]}"
    do
        if [ $nn = "mongodb" ]
        then
            deploy_mongodb $nn
        else
            echo -e "$nn"
        fi
    done
}

deploy_processes


wait ${PID_LIST}
exit 0