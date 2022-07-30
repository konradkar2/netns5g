# netns5g

A free5gc and UERANSIM deployment using Linux network namespaces.

Currently supporting deployment of single UPF, single gNB

## How does it work?
Basicaly every NF gets deployed on its own Network Namespace, with its own interfaces - each of them connected to single linux bridge.
## Features

- free5gc + UERANSIM deployment
- No kubernetes needed
- Quick executable replacement
- Easy traffic capture in runtime - every interface can be seen from host side



## Requirements

- all free5gc dependencies
- all UERANSIM dependencies
- you have to use your own free5gc, UERANSIM binaries - just edit the config so the script knows where they are
## Usage

1. Initialize environment (create namespaces and virtual interfaces)

    ```
    sudo ./env-init.sh
    ```
2. Deploy NFs
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

    ```
    sudo ip netns exec ue ping 10.0.130.1 -I uesimtun0
    ```
    10.0.130.1 is UPF's n3 interface, currently forwarding to N6 interface is not supported as this is not in the scope of core network - this can be done using NAT
5. Cleanup
    
    Execute Ctrl+c on console which runs "sudo ./deploy.sh"

    Cleanup environment (removes all network namespaces and interfaces):
    ```
    sudo ./env-cleanup.sh
    ```
    
## free5gc webconsole

Webconsole executable has to placed in same location as other NF.


To access it just go to http://10.0.123.201:5000 on your host browser.

## Traffic capture

Each NF endpoint traffic can be separetely captured from host.
Sum of the traffic can be found at br1.

![Alt text](assets/traffic.png?raw=true "Traffic")

