#!/bin/bash

echo 'Passw0rd!' | sudo -S kubeadm reset --force --ignore-preflight-errors strings 2>/dev/null

if sudo @lab.Variable(k8sToken) 2>&1 | grep -q -F 'This node has joined the cluster'; 
then
    printf "[%s Join] Successfully joined cluster \n" "$(hostname)"
    echo true
else
    printf "[%s Join] Failed to join cluster with token: @lab.Variable(k8sToken) \n" "$(hostname)" 1>&2
    echo false
fi
