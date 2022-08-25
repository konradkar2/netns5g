# Netns5g

A free5gc and UERANSIM deployment using Linux network namespaces.

Currently supporting the deployment of single UPF, single gNB

## How does it work
Every NF gets deployed on its own Network Namespace, with its interfaces - each of them connected to a single Linux bridge.

This solution is not as flexible as existing ones using Kubernetes and Docker, but requires a lot less configuration and is easier for changes, e.g. to use your own compiled binaries.

## Features

- free5gc + UERANSIM deployment
- No Kubernetes is needed
- Easy traffic capture in runtime - every interface can be seen from the host side



## Requirements

- all free5gc dependencies
- all UERANSIM dependencies
- you have to provide free5gc, UERANSIM binaries - just edit values.yaml and point their location
## Usage

1. Initialize environment (create namespaces and virtual interfaces)

    ```
    sudo ./env-init.sh
    ```
2. Deploy free5gc
    ```
    sudo ./deploy.sh
    ```
3. Deploy RAN

    This step has to be done manually

    Deploy gNB
    ```
    sudo ip netns exec gnb <UERANSIM gNB executable> -c ./config/free5gc-gnb.yaml
    ```
    Deploy ue
    ```
    sudo ip netns exec ue <UERANSIM ue executable> -c ./config/free5gc-ue.yaml
    ```
4. Test

    When uesimtun0 gets created, run:

    UE to UPF n3 interface
    ```
    sudo ip netns exec ue ping 10.0.130.1 -I uesimtun0
    ```
    UE to DN "internet"
    ```
    sudo ip netns exec ue ping 10.0.1.2 -I uesimtun0
    ```
5. Cleanup

    Execute Ctrl+c on console which runs "sudo ./deploy.sh"

    Cleanup environment (removes all network namespaces and interfaces):
    ```
    sudo ./env-cleanup.sh
    ```

## free5gc webconsole

Webconsole executable has to be placed in the same location as other NF.


To access it just go to http://10.0.123.201:5000 on your host browser.

## Traffic capture

Each NF endpoint traffic can be separately captured from the host.
The sum of the traffic can be found at br1.

![Alt text](assets/traffic.png?raw=true "Traffic")

## Tested environment

- OS: Linux Manjaro, Kernel 5.15.49-1-MANJARO
- go 1.14.4
- free5gc 3.2.0
- gtp5g 0.6.2
- UERANSIM, commit 5819ee470f6a30e62faf8e56a79cfb09806ccc99
- gcc 12.1.0

