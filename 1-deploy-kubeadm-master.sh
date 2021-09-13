#!/bin/bash
multipass launch ubuntu --name master --cpus 4 --mem 4G --disk 15G
multipass exec master -- bash -c 'wget https://packages.cloud.google.com/apt/doc/apt-key.gpg'
multipass exec master -- bash -c 'sudo apt-key add apt-key.gpg'
multipass exec master -- bash -c 'sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"'
multipass exec master -- bash -c 'cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF'
multipass exec master -- bash -c 'sudo modprobe overlay'
multipass exec master -- bash -c 'sudo modprobe br_netfilter'
multipass exec master -- bash -c 'cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF'
multipass exec master -- bash -c 'sudo sysctl --system'
multipass exec master -- bash -c 'sudo apt-get update'
multipass exec master -- bash -c 'sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release containerd'
multipass exec master -- bash -c 'sudo mkdir /etc/containerd'
multipass exec master -- bash -c 'sudo containerd config default > sudo /etc/containerd/config.toml'
multipass exec master -- bash -c 'sudo systemctl restart containerd'
multipass exec master -- bash -c 'sudo systemctl enable containerd'
#multipass exec master -- bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
#multipass exec master -- bash -c 'echo \
#  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
#  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
#multipass exec master -- bash -c 'sudo apt-get update'
#multipass exec master -- bash -c 'sudo apt-get install -y docker-ce docker-ce-cli containerd.io'
#multipass exec master -- bash -c 'sudo groupadd docker'
#multipass exec master -- bash -c 'sudo usermod -aG docker $USER'
# Setup daemon.
#multipass transfer daemon.json master:
#multipass exec master -- bash -c 'sudo cp /home/ubuntu/daemon.json /etc/docker/daemon.json'
#multipass exec master -- bash -c 'sudo mkdir -p /etc/systemd/system/docker.service.d'
# Restart docker.
multipass exec master -- bash -c 'sudo systemctl daemon-reload'
#multipass exec master -- bash -c 'sudo systemctl restart docker'
multipass exec master -- bash -c 'sudo apt-get install -y kubelet kubeadm kubectl'
multipass exec master -- bash -c 'sudo apt-mark hold kubelet kubeadm kubectl'
multipass exec master -- bash -c 'sudo swapoff -a'
multipass exec master -- bash -c  "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
#multipass exec master -- bash -c 'sudo systemctl disable --now ufw >/dev/null 2>&1'
#multipass exec master -- bash -c 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'
multipass exec master -- bash -c 'sudo kubeadm init --pod-network-cidr=192.178.0.0/16'
multipass exec master -- bash -c 'sudo cat /etc/kubernetes/admin.conf' > kubeconfig.yaml
export KUBECONFIG=kubeconfig.yaml
cilium install
# kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml
echo "now deploying calico ...."
#KUBECONFIG=kubeconfig.yaml kubectl create -f polycube.yaml
KUBECONFIG=kubeconfig.yaml kubectl get nodes -o wide
echo "Enjoy the kubeadm made Kubernetes 1.6.x on Multipass"
echo "Now deploying the worker nodes"