#!/bin/bash

####################################
## WORKERNODES LIST, UPDATE ME!!! ##
####################################
# WORKERNODES should contain the names of all worker nodes when the lab is started.

WORKERNODES=("k8s-worker1" "k8s-worker2")

########################
## Certificate Update ##
########################

# Check certificate expiration
if echo 'Passw0rd!' | sudo -S kubeadm alpha certs check-expiration 2>/dev/null | grep -q -F 'invalid';  
then
    printf "[Certificate Renewal] Invalid certificates found, attempting to update. \n"

    # Make backup of certificates

    mkdir -p "$HOME"/k8s-old-certs/pki
    sudo /bin/cp -p /etc/kubernetes/pki/*.* "$HOME"/k8s-old-certs/pki
    #ls -l "$HOME"/k8s-old-certs/pki/

    sudo /bin/cp -p /etc/kubernetes/*.conf $HOME/k8s-old-certs
    #ls -ltr "$HOME"/k8s-old-certs

    mkdir -p "$HOME"/k8s-old-certs/.kube
    sudo /bin/cp -p ~/.kube/config "$HOME"/k8s-old-certs/.kube/.
    #ls -l "$HOME"/k8s-old-certs/.kube/.

    # Renew certificates and check expiration dates

    sudo kubeadm alpha certs renew all 2>/dev/null

    # Check that the certificates have been renewed by looking for the "residual time" value of invalid.
    # This will be present if ANY certificate is invalid.
    if sudo kubeadm alpha certs check-expiration 2>/dev/null | grep -q 'invalid'; 
    then
        printf "[sudo kubeadm alpha certs renew all] Failed to update all certificates \n " 1>&2
        echo false
    else
        printf "[sudo kubeadm alpha certs renew all] Successfully updated certificates \n"
    fi

    # Verify if kublet.conf file was updated with new certificate information by comparing it with backup file

    #sudo diff $HOME/k8s-old-certs/kubelet.conf /etc/kubernetes/kubelet.conf

    # If no output, file was not updated. Update kubelet.conf.

    cd /etc/kubernetes

    sudo chmod 666 kubelet.conf

    sudo kubeadm alpha kubeconfig user --org system:nodes --client-name system:node:"$(hostname)" > kubelet.conf 2>/dev/null

    # Verify update to kubelet.conf file.

    #sudo diff $HOME/k8s-old-certs/kubelet.conf /etc/kubernetes/kubelet.conf

    # Copy updated admin.conf to user config file

    sudo cp /etc/kubernetes/admin.conf ~/.kube/config

    # Verify update to file. You should see output. If no output, something is wrong. Check your steps.

    #sudo diff ~/.kube/config $HOME/k8s-old-certs/.kube/config

    # Restart the kubelet service

    sudo systemctl daemon-reload
    sudo systemctl restart kubelet

    # Check that the certificates have been applied and the user can connect to kubectl
    # Will return a connection error if this is not possible. 
    # This test will make 30 attempts, and wait 1 second between each failed check.
    i=1
    while [ "$i" -le 30 ];
    do
        printf "kubectl connection try: %s\n" "$i"
        if kubectl get nodes 2>&1 | grep -q 'refused'; 
        then
            sleep 1
            ((i++))
        else
            break
        fi        
    done

    if kubectl get nodes 2>&1 | grep -q 'k8s-master1'; 
    then
        printf "[Certificate renewal] Successfully updated certificates \n"
        echo true
    else
        printf "[Certificate renewal] Failed to place updated certificates in all locations \n" 1>&2
        echo false
    fi   

else    
    printf "[Certificate Renewal] Warning: No invalid certificates, attempting to update Nodes \n "
    echo false
fi


###################
## Node Deletion ##
###################
# Delete the worker nodes to re-join with updated certificates
# Each node will be attempted up-to 5 times, but are expected to succeed on the first.
# A connection failure during validation will trigger an error



# Interate over the array of worker node names, and delete each one from the cluster
for wnode in "${WORKERNODES[@]}"
do
    i=0
    while [ "$i" -le 5 ];
    do
        if kubectl get nodes 2>&1 | grep -q 'refused'; 
        then
            printf "[Delete %s] Warning: Failed to connect to kubectl on attempt: %s\n" "$wnode" "$i" 
        fi  

        if kubectl get nodes | grep -q -F "$wnode"; 
        then
            printf "[Delete %s] Attempting to deleting node %s\n" "$wnode" "$wnode"
            kubectl delete node "$wnode"
        else
            printf "[Delete %s] Successfully deleted node from master \n" "$wnode"
            break
        fi
        ((i++))
    done
done

# Confirm that all workers are deleted from master
if kubectl get nodes 2>&1 | grep -q 'refused'
then
    printf "[Verify no workers] Failed to connect to kubectl \n" 1>&2
    echo false
else
    if kubectl get nodes | grep -q 'worker'; 
    then
        printf "[Verify no workers] Failed to delete all worker nodes from master \n" 1>&2
        echo false
    else
        printf "[Verify no workers] Successfully deleted all worker nodes from master \n"
    fi
fi

##################
## Create Token ##
##################

# Generate an up-to-date boot-strap token to join new worker nodes to the VM
TOKEN=$(kubeadm token create --print-join-command 2>/dev/null)

# Test the existence of the new token by confirming the existence of the kubeadm join command.
if echo "$TOKEN" | grep -q -F 'kubeadm join'; 
then
    set_lab_variable "k8sToken" "$TOKEN"
    printf "[Token creation] Successfully created: %s \n" "$TOKEN"
    echo true
else
    printf "[Token creation] Failed to create new token \n" 1>&2
    echo false
fi
