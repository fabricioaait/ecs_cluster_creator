# Ecs_Cluster_Creator

This project deploys a production-ready **ECS Fargate cluster** on AWS using Terraform, with an Application Load Balancer (ALB), persistent logging, and optional monitoring with Prometheus.  
It also serves a custom HTML page via NGINX and demonstrates best practices for infrastructure-as-code.

---

## Features

- **VPC** with public subnets and Internet Gateway
- **ECS Cluster** (Fargate launch type)
- **ECS Service** running NGINX, serving a custom `index.html`
- **Application Load Balancer** (ALB) for public access
- **CloudWatch Logs** for ECS containers
- **IAM roles** for ECS task execution
- **Prometheus monitoring** (optional, with persistent EFS storage and ALB)
- **Modular, production-ready Terraform code**

---

## File Structure

- `main.tf` – Core infrastructure: VPC, ALB, ECS cluster/service, IAM, logging
- `networking.tf` – VPC, subnets, routing, and ALB resources
- `ecs.tf` – ECS cluster, task definition, service, and CloudWatch log group
- `role.tf` – IAM roles and policies for ECS task execution
- `prometheus.tf` – (Optional) Prometheus monitoring stack: EFS, ECS task/service, ALB
- `variables.tf` – Input variables (customize as needed)
- `outputs.tf` – Useful outputs (ALB DNS, ECS cluster info)
- `index.html` – Custom HTML page served by NGINX

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.3+
- AWS CLI configured (`aws configure`)
- An AWS account with permissions to create VPC, ECS, ALB, EFS, IAM, etc.

---

## Usage

1. **Clone this repository:**
   ```sh
   git clone <repo-url>
   cd VeracrossECS
   ```

2. **Initialize Terraform:**
   ```sh
   terraform init
   ```

3. **Review and customize variables (optional):**
   - Edit `variables.tf` as needed.

4. **Apply the configuration:**
   ```sh
   terraform apply
   ```
   Confirm with `yes` when prompted.

5. **Access your application:**
   - After apply, Terraform will output the ALB DNS name.
   - Open the URL in your browser to see the custom "Fabricio's ECS Cluster" page.

6. **(Optional) Prometheus Monitoring:**
   - Ensure your `prometheus.yml` is uploaded to the root of your EFS file system.
   - The Prometheus UI will be available at the outputted ALB DNS on port 9090.

---

## Customizing the Web Page

- Edit `index.html` in the project root to change the content served by NGINX.
- The ECS task definition is configured to inject this file into the running container.

---

## Monitoring with Prometheus

- Prometheus is deployed as a separate ECS service with persistent EFS storage.
- To use, upload your `prometheus.yml` config to the root of the EFS file system.
- The Prometheus UI is exposed via its own ALB (see Terraform outputs).

---

## Security Notes

- The ALB and Prometheus are publicly accessible by default. Restrict security group ingress for production.
- IAM roles are scoped for ECS task execution; review and restrict as needed.

---

## Cleanup

To destroy all resources:
```sh
terraform destroy
```

---

## License

MIT

---

## Author

Fabricio (and contributors)
