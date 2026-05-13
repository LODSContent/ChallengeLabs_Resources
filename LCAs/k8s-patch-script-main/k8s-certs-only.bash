#!/bin/bash

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
    printf "[Certificate Renewal] Abort: No invalid certificates \n "
    echo false
fi
