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
    local nf=$1 #also namespace

    local binary_path=""$values_free5gc_binaries_dir"/$nf"
    local config_path=""$values_free5gc_config_dir"/"$nf"cfg.yaml"
    local nf_log=""$values_log_dir"/"$nf".log"
    local core_log=""$values_log_dir"/"$values_log_free5gc_filename""

    echo $binary_path
    echo $core_log
    ip netns exec $nf $binary_path -c $config_path -l $nf_log -lc $core_log &
    PID_LIST+=($!)
}


deploy_processes(){
    for nn in "${values_network_namespaces[@]}"
    do
        if [ $nn = "mongodb" ]
        then
            deploy_mongodb $nn
        else
            deploy_nf $nn
        fi
        sleep 2
    done
}

deploy_processes


wait ${PID_LIST}
exit 0