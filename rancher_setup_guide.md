# Rancher Installation Guide (Helm)

This guide explains how to install the **Rancher Management Server** on your Kubernetes cluster.

> [!NOTE]
> **Clarification on "Per Node" Installation:**
> You do **not** need to install Rancher manually on each worker and master node.
> Rancher is an application that runs *on top* of your Kubernetes cluster. You install it once (using Helm), and Kubernetes automatically schedules the Rancher pods to run on your nodes.

## Prerequisites

*   A running Kubernetes cluster (which you just built).
*   `kubectl` configured to talk to your cluster.
*   **Helm** (Package manager for Kubernetes).

## Step 1: Install Helm

If you haven't installed Helm on your control plane node yet:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Step 2: Add Helm Repositories

Add the repositories for Rancher and Cert-Manager (required for SSL certificates).

```bash
# Add Rancher repo
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

# Add Jetstack repo (for cert-manager)
helm repo add jetstack https://charts.jetstack.io

# Update repos
helm repo update
```

## Step 3: Install Cert-Manager

Rancher requires `cert-manager` to manage SSL certificates for secure communication.

1.  **Install CustomResourceDefinitions (CRDs):**

    ```bash
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml
    ```

2.  **Install Cert-Manager via Helm:**

    ```bash
    kubectl create namespace cert-manager
    
    helm install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --version v1.15.3
    ```

3.  **Verify Cert-Manager:**
    Check that the pods are running:
    ```bash
    kubectl get pods --namespace cert-manager
    ```

## Step 4: Install Rancher

Now install Rancher itself. You need to choose a hostname (e.g., `rancher.my-domain.com`). If you don't have a real domain, you can use a fake one and map it in your `/etc/hosts` file later.

```bash
kubectl create namespace cattle-system

# Replace 'rancher.my.org' with your desired hostname
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.my.org \
  --set bootstrapPassword=admin
```

## Step 5: Verify Installation

Wait for the Rancher rollout to complete:

```bash
kubectl -n cattle-system rollout status deploy/rancher
```

Once finished, you can see the pods:

```bash
kubectl -n cattle-system get deploy rancher
```

## Step 6: Access Rancher UI

1.  **Get the Service IP:**
    Rancher creates a service. If you are on bare metal without a LoadBalancer, you might need to use `NodePort` or `kubectl port-forward` to access it.

    **Quick Access (Port Forwarding):**
    To access it immediately from your local machine:
    ```bash
    kubectl -n cattle-system port-forward svc/rancher 8443:443 --address 0.0.0.0
    ```
    Now open `https://<YOUR_NODE_IP>:8443` in your browser.

2.  **Login:**
    *   **Username:** `admin`
    *   **Password:** `admin` (or whatever you set in Step 4).

You will be greeted by the Rancher dashboard, which gives you full control over your cluster!
