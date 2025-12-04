# Kubernetes Node Setup Guide (Ubuntu 22.04 Bare Metal)

This guide outlines the steps to build a Kubernetes node on a bare metal Ubuntu 22.04 machine using `kubeadm`.

## Prerequisites

*   **OS:** Ubuntu 22.04 LTS
*   **Hardware:**
    *   Control Plane: 2 CPU, 2GB RAM minimum
    *   Worker: 1 CPU, 2GB RAM minimum
*   **Network:** Unique hostname, MAC address, and product_uuid for every node.
*   **Privileges:** Sudo access.

## Step 1: System Preparation (All Nodes)

Run these commands on **all** nodes (control plane and workers).

### 1. Disable Swap
Kubernetes requires swap to be disabled.
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### 2. Load Kernel Modules
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

### 3. Configure Sysctl
```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

## Step 2: Install Container Runtime (All Nodes)

We will use `containerd`.

### 1. Install Containerd
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io
```

### 2. Configure Containerd
Generate default configuration and set SystemdCgroup to true.
```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
```

## Step 3: Install Kubernetes Components (All Nodes)

Install `kubeadm`, `kubelet`, and `kubectl`.

```bash
# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Download the public signing key for the Kubernetes package repositories:
# (Note: Check for the latest version, here using v1.29 as an example)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes apt repository:
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

## Step 4: Initialize Control Plane (Control Plane Node Only)

**Only run this on the machine intended to be the master/control plane.**

```bash
# Replace <CONTROL_PLANE_IP> with the IP of this machine
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=<CONTROL_PLANE_IP>
```

**Post-Initialization:**
Follow the instructions output by `kubeadm init` to configure `kubectl` for your user:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Save the Join Command:**
The output will also contain a `kubeadm join` command. Save this! You will need it to join worker nodes.

## Step 5: Install Pod Network Add-on (Control Plane Node Only)

Install Calico (or another CNI like Flannel).

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
```
*Note: Ensure the CIDR in `custom-resources.yaml` matches your `--pod-network-cidr`.*

## Step 6: Join Worker Nodes (Worker Nodes Only)

Run the join command you saved from Step 4 on each worker node.

```bash
sudo kubeadm join <CONTROL_PLANE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

## Verification

On the control plane node, check the status of the nodes:
```bash
kubectl get nodes
```
All nodes should eventually reach the `Ready` status.
