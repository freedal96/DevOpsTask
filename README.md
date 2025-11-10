<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<h3>DevOpsTask - README</h3>
</head>
<body>

<h1>DevOpsTask - Web Application CI/CD Pipeline</h1>

<p>This repository contains a fully automated DevOps pipeline to deploy a lightweight web application.This is implemented on a single-node Kubernetes cluster on WSL (Windows Subsystem for Linux). For production environments, this setup can be extended to AWS, GCP, or Azure managed Kubernetes clusters:
:</p>

<ul>
    <li>Ubuntu Linux (headless)</li>
    <li>Ansible for environment setup</li>
    <li>Docker for containerization</li>
    <li>Kubernetes & Helm for deployment</li>
    <li>Jenkins for CI/CD</li>
    <li>Kubernetes Secrets for secure credentials</li>
    <li>Trivy for security scanning</li>
</ul>

<h2>Repository Structure</h2>
<pre>
.
├── ansible/             # Ansible playbooks for Ubuntu setup
├── app/                 # Web application code (Node.js/Python/Go)
├── helm/                # Helm chart for Kubernetes deployment
├── Jenkinsfile          # CI/CD pipeline
├── Dockerfile           # Container definition
└── README.md
</pre>

<h2>Usage Instructions</h2>

<h3>1. Provision Infrastructure (Ansible)</h3>
<p>Run the playbook on your Ubuntu host to install Docker, Kubernetes tools, Helm, and Jenkins:</p>
<pre>
ansible-playbook -i inventory.ini playbook.yaml --ask-become-pass
</pre>

<h3>2. Docker Build & Run Locally</h3>
<pre>
cd app
docker build -t freedalelan/webapp:latest .
docker run -p 8000:8000 freedalelan/webapp:latest
curl http://localhost:8000/health
</pre>

<h3>3. Kubernetes Deployment with Helm</h3>
<p>Deploy the application to your cluster using Helm:</p>
<pre>
kubectl create secret generic webapp-secrets \
  --from-literal=DB_USER=myuser \
  --from-literal=DB_PASS=supersecretpassword

kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=mydockerhubuser \
  --docker-password=MY_DOCKERHUB_TOKEN \
  --docker-email=you@example.com

cd helm
helm upgrade --install webapp . \
  --set image.repository=freedalelan/webapp \
  --set image.tag=latest \
  --set secrets.dockerRegistry=dockerhub-secret
</pre>

<h2>CI/CD Pipeline Explanation</h2>
<p>The Jenkins pipeline automates the following steps:</p>
<ol>
    <li><strong>Install Trivy:</strong> Ensures vulnerability scanning is available on the Jenkins agent.</li>
    <li><strong>Build Docker Image:</strong> Builds the application container and tags it with the Jenkins build ID.</li>
    <li><strong>Run Trivy Scans:</strong>
        <ul>
            <li>Filesystem scan of source code for vulnerabilities.</li>
            <li>Container image scan for CVEs.</li>
        </ul>
    </li>
    <li><strong>Container Health Check:</strong> Runs the container locally and checks <code>/health</code> endpoint.</li>
    <li><strong>Push Docker Image to DockerHub:</strong> Authenticates using Jenkins credentials and pushes image with both build-specific and <code>latest</code> tags.</li>
    <li><strong>Helm Setup:</strong> Installs Helm CLI if not already present.</li>
    <li><strong>Deploy to Kubernetes:</strong> Uses Helm upgrade/install with:
        <ul>
            <li>Image repository & tag</li>
            <li>Secrets injection</li>
            <li>Replica configuration</li>
        </ul>
    </li>
    <li><strong>Verify Deployment:</strong> Checks rollout status and pod health using <code>kubectl</code>.</li>
</ol>

<h2>Secrets Management</h2>
<ul>
    <li><strong>DockerHub credentials:</strong> Stored securely in Jenkins and injected during pipeline execution.</li>
    <li><strong>Application secrets:</strong> Stored as Kubernetes Secrets (e.g., <code>webapp-secrets</code>) and injected into Pods as environment variables.</li>
    <li>Pods reference secrets via Helm templates (<code>envFrom.secretRef</code>).</li>
</ul>

<h2>Security Scanning</h2>
<p>All images and source code are scanned using <a href="https://github.com/aquasecurity/trivy">Trivy</a> to detect:</p>
<ul>
    <li>Vulnerabilities in application dependencies</li>
    <li>Misconfigurations in Docker images</li>
</ul>

<h2>Post-Build Cleanup</h2>
<p>The pipeline automatically prunes unused Docker images and containers to maintain the build environment clean.</p>

<h2>Pipeline Success Criteria</h2>
<ul>
    <li>Docker image builds successfully</li>
    <li>Trivy scan passes (or reports warnings)</li>
    <li>Health check endpoint returns 200</li>
    <li>Image is pushed to DockerHub</li>
    <li>Helm deployment succeeds and rollout completes</li>
</ul>

<h2>Notes for Interview</h2>
<p>This submission demonstrates:</p>
<ul>
    <li>End-to-end automated CI/CD pipeline</li>
    <li>Secure handling of secrets using Kubernetes and Jenkins</li>
    <li>Container security scanning integrated in CI</li>
    <li>Scalable deployment using Helm and Kubernetes</li>
</ul>

</body>
</html>
