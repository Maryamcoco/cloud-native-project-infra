
# ☁️Cloud-Native Infrastructure Provisioning (IaC)
---
This repository, cloud-native-project-infra, contains the **Infrastructure as Code (IaC)** powered by **Terraform** to provision a complete development and observability environment on **Amazon Web Services (AWS).**

*This infrastructure is the foundation for CI/CD and monitoring stack, supporting the application and toolset defined in the companion repository:*🔗 **Application & CI/CD Project:** [**Cloud-Native CI/CD & Observability**](https://github.com/Maryamcoco/cloud-native-cicd-observability.git)

## 🚀 Architecture & Components

The Terraform configuration creates a **Two-Tier Architecture** on AWS using two linked **EC2 instances** dedicated to CI/CD and Observability roles.

### 1. Infrastructure (Terraform)

| Component | AWS Resource(s) | Details |
| :--- | :--- | :--- |
| **Networking** | `aws_default_vpc`, `aws_default_subnet` | Utilizes the default VPC and a default subnet in `us-east-1a`. |
| **Security** | `aws_security_group` (`maryam_sg`) | A single Security Group open to the internet (`0.0.0.0/0`) for all key ports (SSH, Jenkins, Prometheus, Grafana, etc.). |
| **Compute** | 2 x `aws_instance` (`t2.xlarge`) | Two EC2 instances provisioned in the `us-east-1` region. |
| **Identity** | `aws_iam_role`, `aws_iam_instance_profile` | An IAM Role is created and attached to the instances, granting permissions like `ec2:Describe*`. |

### 2. EC2 Instance Roles and Software (User Data Scripts)

The two EC2 instances are configured with distinct roles:

| Instance | Role & Primary Tool | Key Software Installed | User Data File |
| :--- | :--- | :--- | :--- |
| **`maryam_instance-1`** | **CI/CD Master** | **Jenkins** (on port 8081), Git, Maven, Docker, Node.js/npm, AWS CLI v2, **kubectl**, **eksctl**, **Node Exporter** (on port 9100), **OWASP ZAP**. | `script1.sh` |
| **`maryam_instance-2`** | **Observability Master** | **Prometheus** (on port 9090), **Grafana** (on port 3000), **Blackbox Exporter** (on port 9115). | `script2.sh.tpl` |

### 3. Monitoring Configuration

The observability master (`maryam_instance-2`) is configured to scrape metrics from the CI/CD master (`maryam_instance-1`):

* **Node Exporter:** Scrapes system metrics from `maryam_instance-1` at `${jenkins_private_ip}:9100`.
* **Jenkins:** Scrapes Jenkins application metrics from `maryam_instance-1` at `${jenkins_private_ip}:8081`.
* **Blackbox Exporter:** Performs external "blackbox" monitoring (HTTP checks) on the public IPs for:
    * The Jenkins interface (`${jenkins_public_ip}:8081`).
    * The Application endpoint (`${jenkins_public_ip}:8080`).

---

## 🔒 Security Design Note
In the interest of rapid deployment and ease of assessment for this portfolio project, certain configurations were made for accessibility:

- **Open Access (0.0.0.0/0):** The security group is intentionally permissive to allow easy validation of all running services (Jenkins, Grafana, Prometheus, etc.). In a production environment, this would be strictly limited to a secure VPN or jump-box IP range.

- **Local State Management:** The project uses local terraform.tfstate. For any collaborative or production deployment, I would implement a remote state backend (e.g., AWS S3 with DynamoDB locking) to ensure state integrity and team collaboration.

- **AMI/Key Placeholders:** The hardcoded ami and key_name are development placeholders. A production solution would use a secure lookup via Terraform Data Sources or a centralized secrets manager.

## 🛠️ Prerequisites

To deploy this infrastructure, you need:

1.  **Terraform CLI** (v1.0.0 or later).
2.  **AWS CLI** installed.
3.  **AWS Credentials:** Your credentials must be configured locally (e.g., via `aws configure` or environment variables) so Terraform can authenticate with AWS.
4.  **SSH Key:** An SSH key named **`maryamkey`** must exist in your AWS account in the `us-east-1` region, as defined in `variables.tf`.
5.  **User Data Scripts:** The files `script1.sh` and `script2.sh.tpl` must be present in the root directory.

## 🚀 How to Deploy

Follow these steps to provision the entire environment:

### 1. Clone the Repository

```bash
git clone [https://github.com/Maryamcoco/cloud-native-project-infra.git](https://github.com/Maryamcoco/cloud-native-project-infra.git)
cd cloud-native-project-infra
```
### 2. Initialize Terraform
*This downloads the AWS provider and initializes the state management.*
```
terraform init
```
### 3. Review the Plan
*Always review the execution plan before making changes.*
```
terraform plan
```
### 4. Apply Changes
*Execute the plan. You will be prompted to type yes to confirm the provisioning of the resources.*
```
terraform apply
```
### 5. Access the Tools
*Once the deployment is complete, you can access the provisioned tools using the public IP address of the respective instance and the ports defined in the Security Group:*

Tool|	Instance |	Default Port|	Access URL
| :- | :- | :-  | :- |
Jenkins	   | maryam_instance-1|	 8081	 | http://[Public IP of Instance 1]:8081
Prometheus	|maryam_instance-2|	 9090|	  http://[Public IP of Instance 2]:9090
Grafana  | maryam_instance-2	| 3000	|  http://[Public IP of Instance 2]:3000

### 🗑️ Cleanup
*To avoid unexpected AWS charges, be sure to destroy all resources when the environment is no longer needed:*
```

terraform destroy
```

## 👩‍💻 Author

**Maryam Abdulrauf**
*DevOps Engineer | Cloud & Automation Enthusiast*
📧 abdulraufmaryam15@gmail.com

💼 [LinkedIn Profile](https://www.linkedin.com/in/maryam-temitope-2a3428373/)
