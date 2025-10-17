# Easyroom Infrastructure Overview

This repository contains the Terraform code for deploying the Easyroom project infrastructure on AWS.

## Architecture Overview

The Easyroom application is deployed across three EC2 instances, each dedicated to a specific tier: Frontend, Backend, and Database. All instances reside within a single Public Subnet in a custom VPC, with carefully configured Security Groups to control traffic flow.

## Key Components

-   **AWS Region**: `ap-southeast-1` (Asia Pacific - Singapore)
-   **VPC**: `10.0.0.0/16` with DNS support enabled.
-   **Public Subnet**: `10.0.1.0/24` with public IP assignment on launch (for Frontend and Backend).
-   **Internet Gateway (IGW)**: For internet connectivity.
-   **EC2 Instances**:
    -   **Frontend Server (t3.micro)**: Runs Apache for static frontend assets. Has a Public IP.
    -   **Backend Server (t3.micro)**: Runs Node.js Express API. Has a Public IP.
    -   **Database Server (t3.micro)**: Runs MySQL in a Docker container. **No Public IP** for enhanced security, accessible only from the Backend Server.
-   **EBS Volumes (gp3, encrypted)**:
    -   Frontend: 20GB
    -   Backend: 20GB
    -   Database: 60GB
-   **Security Groups**:
    -   **Frontend SG**: Allows HTTP (80), HTTPS (443) from Internet, and SSH (22) from a specified IP.
    -   **Backend SG**: Allows API traffic (Port 3000) from Frontend SG, and SSH (22) from a specified IP.
    -   **Database SG**: Allows MySQL traffic (Port 3306) from Backend SG, and SSH (22) from a specified IP.
-   **SSH Key Pair**: Automatically generated, private key saved locally (`easyroom-key.pem`) for SSH access.
-   **IMDSv2 Enforcement**: Instance Metadata Service Version 2 is enforced for all EC2 instances for improved security.

## Infrastructure Diagram

Here's a simplified architectural diagram of the Easyroom infrastructure:

<img src="https://github.com/panyakornt65/build-infra-easyroom/blob/main/easyroom-infra/generated-diagrams/easyroom_infrastructure_diagram_simplified.png?raw=true" alt="Easyroom Infrastructure Diagram" width="800"/>

## Access Information (After Terraform Apply)

-   **Frontend Public IP**: `[Public IP of Frontend Server]`
-   **Backend Public IP**: `[Public IP of Backend Server]`
-   **Database Private IP**: `[Private IP of Database Server]`

**SSH Commands:**
-   **Frontend**: `ssh -i easyroom-infra/easyroom-key.pem ubuntu@[Frontend Public IP]`
-   **Backend**: `ssh -i easyroom-infra/easyroom-key.pem ubuntu@[Backend Public IP]`
-   **Database**: `ssh -i easyroom-infra/easyroom-key.pem ubuntu@[Database Private IP]` (Accessed from Frontend/Backend)

**Important**: The `easyroom-infra/easyroom-key.pem` file is your private key. Keep it secure and do not share it.

---
