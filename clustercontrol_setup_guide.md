# ClusterControl Community Edition Installation Guide (Docker)

This guide explains how to install **ClusterControl Community Edition** using Docker.

## Prerequisites

*   **Docker** installed on your machine.
*   **Docker Compose** (optional, but recommended for easier management).

## Method 1: Quick Start (Docker Run)

The fastest way to get ClusterControl up and running is using the `docker run` command.

1.  **Pull the Image:**
    ```bash
    docker pull severalnines/clustercontrol
    ```

2.  **Run the Container:**
    This command runs ClusterControl and maps port `5000` on your host to port `80` in the container.
    ```bash
    docker run -d --name clustercontrol \
      -p 5000:80 \
      -h clustercontrol \
      severalnines/clustercontrol
    ```

3.  **Access the UI:**
    Open your browser and go to:
    `http://<YOUR_HOST_IP>:5000/clustercontrol`

4.  **Initial Setup:**
    *   Create a default admin user and password when prompted.

## Method 2: Docker Compose (Recommended)

Using Docker Compose allows you to persist data (like configuration and backups) even if the container is recreated.

1.  **Create a `docker-compose.yml` file:**

    ```yaml
    version: '3'
    services:
      clustercontrol:
        image: severalnines/clustercontrol
        container_name: clustercontrol
        hostname: clustercontrol
        ports:
          - "5000:80"
          - "443:443"
        volumes:
          - ./cmon.d:/etc/cmon.d
          - ./cmon-lib:/var/lib/cmon
          - ./ssh:/root/.ssh
        restart: always
    ```

2.  **Start the Service:**
    ```bash
    docker-compose up -d
    ```

3.  **Access the UI:**
    `http://<YOUR_HOST_IP>:5000/clustercontrol`

## Important Notes

*   **SSH Access:** ClusterControl manages databases via SSH. If you want it to manage other containers or servers, you need to set up passwordless SSH from the ClusterControl container to your target database nodes.
    *   You can generate a key inside the container: `docker exec -it clustercontrol ssh-keygen -t rsa`
    *   Then copy it to your targets: `docker exec -it clustercontrol ssh-copy-id root@<TARGET_IP>`
*   **Community Edition:** This version is free but has some feature limitations compared to the Enterprise version (e.g., some advanced backup and recovery features might be restricted after the trial period).
