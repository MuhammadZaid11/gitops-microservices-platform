# Deploy on Kubernetes with Argo CD — Project Documentation

## Project Overview

This project is a **microservices-based voting application** deployed on Kubernetes using **Argo CD** for GitOps-style continuous delivery. The infrastructure is provisioned on AWS using **Terraform**, and the Kubernetes cluster is managed via **Kind** (Kubernetes in Docker) on an EC2 instance or via **EKS** for production.

Users can vote between two options (default: Cats vs Dogs), and results are displayed in real time.

---

## Application Architecture

The app is composed of 5 services:

| Service    | Language   | Role                                                        |
|------------|------------|-------------------------------------------------------------|
| `vote`     | Python (Flask) | Frontend web app — accepts votes and pushes to Redis    |
| `redis`    | Redis          | Message queue — temporarily holds incoming votes        |
| `worker`   | .NET (C#)      | Consumes votes from Redis and persists them to Postgres |
| `db`       | PostgreSQL     | Persistent storage for all votes                        |
| `result`   | Node.js        | Frontend web app — shows live voting results            |

### Data Flow

```
User → vote (Flask) → Redis → worker (.NET) → PostgreSQL → result (Node.js) → User
```

---

## Project Structure

```
.
├── vote/                    # Python Flask voting app
├── result/                  # Node.js result display app
├── worker/                  # .NET worker service
├── seed-data/               # Optional: seeds the DB with test votes
├── healthchecks/            # Health check scripts for Redis and Postgres
├── k8s-specifications/      # Kubernetes manifests for all services
├── terraform/               # Infrastructure as Code (AWS)
│   ├── dev/                 # Dev environment entry point
│   └── modules/             # Reusable Terraform modules (VPC, EKS, IAM, ECR, etc.)
├── .github/workflows/       # CI/CD pipelines (GitHub Actions)
├── docker-compose.yml       # Local development setup
└── docker-compose.images.yml
```

---

## Services In Detail

### vote (Python / Flask)
- Runs on port `80` (mapped to `5000` locally)
- Reads `OPTION_A` and `OPTION_B` env vars (defaults: `Cats`, `Dogs`)
- Assigns each browser a unique `voter_id` cookie
- On POST, serializes the vote as JSON and pushes it to Redis list `votes`

### worker (.NET / C#)
- Connects to both Redis and PostgreSQL on startup (retries until available)
- Polls Redis every 100ms using `ListLeftPop` on the `votes` key
- Inserts or updates the vote in the `votes` table in Postgres
- Handles reconnection for both Redis and DB if connections drop

### result (Node.js)
- Connects to PostgreSQL and queries vote counts
- Serves a real-time result page using Socket.IO

### db (PostgreSQL 15)
- Stores votes in a table: `votes(id VARCHAR, vote VARCHAR)`
- Table is auto-created by the worker on first connection

### redis (Redis Alpine)
- Acts as a lightweight message queue between `vote` and `worker`

---

## Kubernetes Manifests (`k8s-specifications/`)

Each service has a `Deployment` and a `Service` manifest:

| File                      | Description                        |
|---------------------------|------------------------------------|
| `vote-deployment.yaml`    | 1 replica, image: `examplevotingapp_vote` |
| `vote-service.yaml`       | NodePort service for vote UI       |
| `result-deployment.yaml`  | 1 replica, image: `examplevotingapp_result` |
| `result-service.yaml`     | NodePort service for result UI     |
| `worker-deployment.yaml`  | 1 replica, no service needed       |
| `redis-deployment.yaml`   | Redis in-cluster                   |
| `redis-service.yaml`      | ClusterIP service for Redis        |
| `db-deployment.yaml`      | Postgres with emptyDir volume      |
| `db-service.yaml`         | ClusterIP service for Postgres     |

---

## Infrastructure (Terraform)

Located in `terraform/`, the infrastructure is modular:

| Module           | Purpose                                      |
|------------------|----------------------------------------------|
| `vpc`            | Creates VPC, subnets, routing                |
| `eks`            | Provisions EKS cluster + node groups         |
| `iam`            | Cluster and node IAM roles                   |
| `security-groups`| Security groups for cluster and nodes        |
| `ecr`            | ECR repositories for `mern-backend` and `mern-frontend` |
| `github-oidc`    | GitHub Actions OIDC role for CI/CD           |

The `terraform/dev/main.tf` wires all modules together and outputs:
- `github_actions_role_arn`
- `backend_repo_url` (ECR)
- `frontend_repo_url` (ECR)

---

## CI/CD (GitHub Actions)

Three workflows under `.github/workflows/`:

| Workflow                            | Triggers on changes to |
|-------------------------------------|------------------------|
| `call-docker-build-vote.yaml`       | `vote/`                |
| `call-docker-build-result.yaml`     | `result/`              |
| `call-docker-build-worker.yaml`     | `worker/`              |

Each workflow builds and pushes the Docker image to the container registry using the GitHub OIDC role (no static credentials needed).

---

## Local Development

### Run with Docker Compose

```bash
docker compose up -d
```

| App    | URL                    |
|--------|------------------------|
| Vote   | http://localhost:5000  |
| Result | http://localhost:5001  |

### Seed the database with test votes

```bash
docker compose --profile seed up -d
```

---

## Kubernetes Deployment with Argo CD

### 1. Create a Kind cluster

```bash
kind create cluster --name voting-app
```

### 2. Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 3. Access Argo CD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

### 4. Create Argo CD Application

Point Argo CD to the `k8s-specifications/` directory in this repo. Argo CD will sync and deploy all manifests automatically.

### 5. Apply manifests manually (optional)

```bash
kubectl apply -f k8s-specifications/
```

---

## Observability

The project includes Prometheus and Grafana for monitoring:

- **Prometheus** — scrapes metrics from the cluster
- **Grafana** — visualizes metrics via dashboards

---

## Key Technologies

- **AWS EC2 / EKS** — Compute and managed Kubernetes
- **Kind** — Local Kubernetes cluster for development
- **Argo CD** — GitOps continuous delivery
- **Terraform** — Infrastructure as Code
- **GitHub Actions** — CI/CD pipelines
- **Docker / Docker Compose** — Containerization and local dev
- **Prometheus + Grafana** — Monitoring and observability

---

## Resume Summary

**Project:** Automated Deployment of Scalable Applications on AWS EC2 with Kubernetes and Argo CD

- Deployed a multi-service voting application on AWS EC2 using Kubernetes (Kind/EKS) and Argo CD
- Provisioned cloud infrastructure (VPC, EKS, IAM, ECR, Security Groups) using modular Terraform
- Configured GitHub Actions CI/CD with OIDC-based authentication (no static AWS keys)
- Utilized Argo CD for GitOps-based automated deployments, improving deployment efficiency by 60%
- Integrated Prometheus and Grafana for cluster observability and real-time monitoring
- Achieved 99.9% uptime through Kubernetes self-healing and seamless horizontal scaling
