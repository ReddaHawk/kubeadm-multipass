#!/bin/bash
NODES=$(echo worker{1..2})
for NODE in ${NODES}; do multipass launch --name ${NODE} --cpus 4 --mem 4G --disk 15G; done

for NODE in ${NODES}; do
multipass exec ${NODE} -- bash -c 'wget https://packages.cloud.google.com/apt/doc/apt-key.gpg'
multipass exec ${NODE} -- bash -c 'sudo apt-key add apt-key.gpg'
multipass exec ${NODE} -- bash -c 'sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"'
multipass exec ${NODE} -- bash -c 'cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF'
multipass exec ${NODE} -- bash -c 'sudo modprobe overlay'
multipass exec ${NODE} -- bash -c 'sudo modprobe br_netfilter'
multipass exec ${NODE} -- bash -c 'cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF'
multipass exec ${NODE} -- bash -c 'sudo sysctl --system'
multipass exec ${NODE} -- bash -c 'sudo apt-get update'
multipass exec ${NODE} -- bash -c 'sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release containerd'
multipass exec ${NODE} -- bash -c 'sudo mkdir /etc/containerd'
multipass exec ${NODE} -- bash -c 'sudo containerd config default > sudo /etc/containerd/config.toml'
multipass exec ${NODE} -- bash -c 'sudo systemctl restart containerd'
multipass exec ${NODE} -- bash -c 'sudo systemctl enable containerd'
multipass exec ${NODE} -- bash -c 'sudo sysctl -w vm.max_map_count=262144'
# Setup daemon.
#multipass transfer daemon.json ${NODE}:
#multipass exec ${NODE} -- bash -c 'sudo cp /home/ubuntu/daemon.json /etc/docker/daemon.json'
#multipass exec ${NODE} -- bash -c 'sudo mkdir -p /etc/systemd/system/docker.service.d'
# Restart docker.
multipass exec ${NODE} -- bash -c 'sudo systemctl daemon-reload'
#multipass exec ${NODE} -- bash -c 'sudo systemctl restart docker'
multipass exec ${NODE} -- bash -c 'sudo apt-get install -y kubelet kubeadm kubectl'
multipass exec ${NODE} -- bash -c 'sudo apt-mark hold kubelet kubeadm kubectl'
multipass exec ${NODE} -- bash -c 'sudo swapoff -a'
multipass exec ${NODE} -- bash -c  "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
#multipass exec ${NODE} -- bash -c 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'
multipass exec ${NODE} -- bash -c 'sudo systemctl enable kubelet.service'
done

echo "Now running kubeadm join nodes"
echo "We're ready soon :-)"

