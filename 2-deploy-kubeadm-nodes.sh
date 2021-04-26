#!/bin/bash
NODES=$(echo worker{1..2})
for NODE in ${NODES}; do multipass launch --name ${NODE} --cpus 4 --mem 6G --disk 20G; done

for NODE in ${NODES}; do
multipass exec ${NODE} -- bash -c 'wget https://packages.cloud.google.com/apt/doc/apt-key.gpg'
multipass exec ${NODE} -- bash -c 'sudo apt-key add apt-key.gpg'
multipass exec ${NODE} -- bash -c 'sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"'
multipass exec ${NODE} -- bash -c 'sudo apt-get update'
multipass exec ${NODE} -- bash -c 'sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release '
multipass exec ${NODE} -- bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
multipass exec ${NODE} -- bash -c 'echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
multipass exec ${NODE} -- bash -c 'sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io'
multipass exec ${NODE} -- bash -c 'sudo groupadd docker'
multipass exec ${NODE} -- bash -c 'sudo usermod -aG docker $USER'
# Setup daemon.
#multipass transfer daemon.json ${NODE}:
#multipass exec ${NODE} -- bash -c 'sudo cp /home/ubuntu/daemon.json /etc/docker/daemon.json'
#multipass exec ${NODE} -- bash -c 'sudo mkdir -p /etc/systemd/system/docker.service.d'
# Restart docker.
multipass exec ${NODE} -- bash -c 'sudo systemctl daemon-reload'
multipass exec ${NODE} -- bash -c 'sudo systemctl restart docker'
multipass exec ${NODE} -- bash -c 'sudo apt-get install -y kubelet kubeadm kubectl'
multipass exec ${NODE} -- bash -c 'sudo apt-mark hold kubelet kubeadm kubectl'
multipass exec ${NODE} -- bash -c 'sudo swapoff -a'
multipass exec ${NODE} -- bash -c  "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
multipass exec ${NODE} -- bash -c 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'
multipass exec ${NODE} -- bash -c 'sudo systemctl enable kubelet.service'
done

echo "Now running kubeadm join nodes"
echo "We're ready soon :-)"

