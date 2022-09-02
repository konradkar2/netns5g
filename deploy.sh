#!/bin/bash


PID_LIST=()

function terminate()
{
    echo "Receive SIGINT, terminating..."
    for ((i=${#PID_LIST[@]}-1;i>=0;i--)); do
        sudo kill -SIGTERM "${PID_LIST[i]}"
        sleep 1
    done

    wait ${PID_LIST}
    exit 0
}
trap terminate SIGINT


deploy_service(){
    local namespace=$1
    local path=$2
    local args=$3
    echo -e "deploying service: [namespace: "$namespace", path: "$path", args: "$args"]"

    ip netns exec $namespace $path $args &

    PID_LIST+=($!)
}

deploy_processes(){
    services_length=$(yq -r ".config.services | length"  values.yaml)
    for (( service_idx=0; service_idx<$services_length; service_idx++ ))
    do
        local service=$(yq -r ".config.services["$service_idx"].name" values.yaml)
        local isDeployDefined=$(yq -r ".config.services["$service_idx"].deploy" values.yaml)
        if [ "$isDeployDefined" == "null" ]
        then
            echo -e "skipping deployment of: $service"
        else
            local namespace=$(yq -r ".config.services["$service_idx"].network.namespace" values.yaml)
            local path=$(yq -r ".config.services["$service_idx"].deploy.path" values.yaml)
            local args=$(yq -r ".config.services["$service_idx"].deploy.args" values.yaml)

            deploy_service "$namespace" "$path" "$args"
            sleep 2
        fi
    done
}

main(){
    export GIN_MODE=release
    deploy_processes

    echo "all services running"
    wait ${PID_LIST}
    exit 0
}

main
