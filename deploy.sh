#!/bin/bash


PID_LIST=()
free5gc_executable_dir=$(yq -r ".deployment.config.free5gc.executableDir"  values.yaml)
free5gc_config_dir=$(yq -r ".deployment.config.free5gc.configDir"  values.yaml)
logging_directory=$(yq -r ".deployment.config.logging.directory"  values.yaml)

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

deploy_mongodb(){
    echo -e "deploy_mongodb: namespace $1"
    local namespace=$1

    local mongodb_executable=$(yq -r ".deployment.config.mongodb.executable"  values.yaml)
    local mongodb_config=$(yq -r ".deployment.config.mongodb.config"  values.yaml)

    ip netns exec "$namespace" "$mongodb_executable" --config "$mongodb_config" &
    PID_LIST+=($!)
}
deploy_nf(){
    echo -e "deploy nf: name $1, namespace $2"
    local name=$1
    local namespace=$2

    local binary_path=""$free5gc_executable_dir"/$name"
    local config_path=""$free5gc_config_dir"/"$name"cfg.yaml"
    local nf_log=""$logging_directory"/"$name".log"
    local core_log=""$logging_directory"/free5gc.log"

    if [ "$name" == "smf" ] ; then
        local uerouting=""$free5gc_config_dir"/uerouting.yaml"
        ip netns exec "$namespace" "$binary_path" -c "$config_path" -l "$nf_log" -lc "$core_log" -u "$uerouting" &
    elif [ "$name" == "webconsole" ] ; then
        config_path=""$free5gc_config_dir"/webuicfg.yaml"
        local public_dir=$(yq -r ".deployment.config.free5gc.webconsole.publicDir"  values.yaml)
        ip netns exec "$namespace" "$binary_path" -c "$config_path" -l "$nf_log" -lc "$core_log" -p "$public_dir" &
    else
        ip netns exec "$namespace" "$binary_path" -c "$config_path" -l "$nf_log" -lc "$core_log" &
    fi
    PID_LIST+=($!)
}

deploy_processes(){
    services_length=$(yq -r ".envConfig.services | length"  values.yaml)
    for (( service_idx=0; service_idx<$services_length; service_idx++ ))
    do
        local deploy=$(yq -r ".envConfig.services["$service_idx"].deploy" values.yaml)
        local service=$(yq -r ".envConfig.services["$service_idx"].name" values.yaml)
        if [ "$deploy" == "false" ]
        then
            echo -e "skipping deployment of: $service"
        else
            local namespace=$(yq -r ".envConfig.services["$service_idx"].namespace" values.yaml)
            if [ "$service" == "mongodb" ]
            then
                deploy_mongodb "$namespace"
                sleep 1
            else
                deploy_nf "$service" "$namespace"
            fi
        fi
        sleep 2
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
