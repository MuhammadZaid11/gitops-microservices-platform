# K8s Voting App — Deployed with Argo CD on AWS

A microservices-based voting application deployed on Kubernetes using **Argo CD** for GitOps continuous delivery. Infrastructure is provisioned on AWS with **Terraform**, and the cluster runs on **Kind** (local) or **EKS** (production).

---

## Architecture

![Architecture](architecture.excalidraw.png)

### Data Flow

```
User → vote (Flask) → Redis → worker (.NET) → PostgreSQL → result (Node.js) → User
```

### Services

| Service  | Technology     | Description                                      |
|----------|----------------|--------------------------------------------------|
| `vote`   | Python / Flask | Frontend — accepts votes, pushes to Redis        |
| `redis`  | Redis          | Message queue between vote and worker            |
| `worker` | .NET / C#      | Consumes votes from Redis, persists to Postgres  |
| `db`     | PostgreSQL 15  | Stores all votes                                 |
| `result` | Node.js        | Frontend — shows live results via Socket.IO      |

---

## Project Structure

```
.
├── vote/                   # Python Flask voting app
├── result/                 # Node.js result app
├── worker/                 # .NET worker service
├── seed-data/              # Seeds DB with test votes (optional)
├── healthchecks/           # Health check scripts for Redis & Postgres
├── k8s-specifications/     # Kubernetes Deployment & Service manifests
├── terraform/
│   ├── dev/                # Dev environment (main.tf, variables, outputs)
│   └── modules/            # VPC, EKS, IAM, ECR, SecurityGroups, GitHub OIDC
├── .github/workflows/      # GitHub Actions CI/CD pipelines
├── docker-compose.yml      # Local development
└── README.md
```

---

## Local Development

**Prerequisites:** Docker, Docker Compose v2

```bash
# Start all services
docker compose up -d
```

| App    | URL                   |
|--------|-----------------------|
| Vote   | http://localhost:5000 |
| Result | http://localhost:5001 |

```bash
# Seed the database with sample votes
docker compose --profile seed up -d

# Tear down
docker compose down
```

---

## Kubernetes Deployment with Argo CD

### Prerequisites

- `kubectl` installed and configured
- `kind` installed (for local cluster)
- Argo CD CLI (optional)

### Step 1 — Create a Kind Cluster

```bash
kind create cluster --name voting-app
```

### Step 2 — Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=120s
```

### Step 3 — Access the Argo CD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

Open https://localhost:8080 and log in with `admin` and the password above.

### Step 4 — Connect the Repository

In the Argo CD UI:
1. Go to **Settings → Repositories** and add this repo
2. Go to **Applications → New App**
3. Set the path to `k8s-specifications/`
4. Set sync policy to **Automatic**

Argo CD will sync and deploy all services automatically.

### Step 5 — Apply Manifests Manually (optional)

```bash
kubectl apply -f k8s-specifications/
kubectl get pods
kubectl get svc
```

---

## Infrastructure (Terraform)

Located in `terraform/`. Uses a modular structure:

| Module           | Purpose                                         |
|------------------|-------------------------------------------------|
| `vpc`            | VPC, subnets, route tables                      |
| `eks`            | EKS cluster and managed node groups             |
| `iam`            | Cluster and node IAM roles                      |
| `security-groups`| Security groups for cluster and nodes           |
| `ecr`            | ECR repositories for container images           |
| `github-oidc`    | GitHub Actions OIDC role (no static AWS keys)   |

```bash
cd terraform/dev
terraform init
terraform plan
terraform apply
```

---

## CI/CD (GitHub Actions)

Three workflows automatically build and push Docker images on code changes:

| Workflow                          | Watches         |
|-----------------------------------|-----------------|
| `call-docker-build-vote.yaml`     | `vote/`         |
| `call-docker-build-result.yaml`   | `result/`       |
| `call-docker-build-worker.yaml`   | `worker/`       |

Authentication uses **GitHub OIDC** — no AWS access keys stored in secrets.

---

## Observability

![Grafana](grafana.png)
![Prometheus](prometheus.png)

- **Prometheus** — scrapes cluster and application metrics
- **Grafana** — dashboards for real-time visualization

---

## Tech Stack

| Category       | Tools                                      |
|----------------|--------------------------------------------|
| Cloud          | AWS EC2, EKS, ECR, VPC, IAM               |
| Kubernetes     | Kind (local), EKS (prod), kubectl          |
| GitOps / CD    | Argo CD                                    |
| IaC            | Terraform                                  |
| CI/CD          | GitHub Actions + OIDC                      |
| Containers     | Docker, Docker Compose                     |
| Monitoring     | Prometheus, Grafana                        |
| Languages      | Python, Node.js, .NET (C#)                 |

---

## Kubernetes Manifests Reference

| Manifest                   | Kind       | Notes                          |
|----------------------------|------------|--------------------------------|
| `vote-deployment.yaml`     | Deployment | 1 replica                      |
| `vote-service.yaml`        | Service    | NodePort                       |
| `result-deployment.yaml`   | Deployment | 1 replica                      |
| `result-service.yaml`      | Service    | NodePort                       |
| `worker-deployment.yaml`   | Deployment | No service (background worker) |
| `redis-deployment.yaml`    | Deployment | In-cluster Redis               |
| `redis-service.yaml`       | Service    | ClusterIP                      |
| `db-deployment.yaml`       | Deployment | Postgres with emptyDir volume  |
| `db-service.yaml`          | Service    | ClusterIP                      |

---

## License

See [MAINTAINERS](MAINTAINERS) for project maintainers.
