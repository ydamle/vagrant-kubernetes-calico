#!/bin/bash -e


install_required_packages ()
{
sudo apt update
sudo apt -y install curl apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt -y install vim git curl wget kubelet=1.23.6-00 kubeadm=1.23.6-00 kubectl=1.23.6-00
#sudo apt -y install vim git curl wget kubelet=1.20.11-00 kubeadm=1.20.11-00 kubectl=1.20.11-00
sudo apt-mark hold kubelet kubeadm kubectl
}

configure_hosts_file ()
{
sudo tee /etc/hosts<<EOF
172.16.8.10 master
172.16.8.11 node-01
#172.16.8.12 node-02
EOF
}

disable_swap () 
{
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
}

configure_sysctl ()
{
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
}

install_docker_runtime () 
{
sudo apt update
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker

sed -i 's/plugins.cri.systemd_cgroup = false/plugins.cri.systemd_cgroup = true/' /etc/containerd/config.toml
}

install_apparmor()
{
	sudo apt install apparmor -y
	sudo apt-get install apparmor-utils -y
}

install_helm()
{
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod 700 get_helm.sh
	./get_helm.sh

}

install_falco()
{
	curl -s https://falco.org/repo/falcosecurity-3672BA8F.asc | apt-key add -
	echo "deb https://download.falco.org/packages/deb stable main" | tee -a /etc/apt/sources.list.d/falcosecurity.list
	apt-get update -y
	apt-get -y install linux-headers-$(uname -r)
	apt-get install -y falco
	systemctl start falco

}

install_trivy()
{
	sudo apt-get install wget apt-transport-https gnupg lsb-release -y
	wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
	echo deb https://aquasecurity.github.io/triv-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sourceslist.d/trivy.list
	sudo apt-et y.gupdate
	sudo apt-get install trivy -y
}

install_required_packages
configure_hosts_file
disable_swap
configure_sysctl
install_docker_runtime
install_apparmor
install_helm
install_falco
install_trivy
