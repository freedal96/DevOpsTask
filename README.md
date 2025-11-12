<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<h3>DevOps - README</h3>
</head>
<body>

<h1>Web Application CI/CD Pipeline</h1>

<p>This repository contains a fully automated DevOps pipeline to deploy a lightweight web application.This is implemented on a single-node Kubernetes cluster on WSL (Windows Subsystem for Linux). For production environments, this setup can be extended to AWS, GCP, or Azure managed Kubernetes clusters:
:</p>

<ul>
    <li>Ubuntu Linux (headless)</li>
    <li>Ansible for environment setup -This playbook runs on <strong>WSL Ubuntu</strong> or headless Ubuntu servers.</li>
    <li>Docker for containerization</li>
    <li>Kubernetes & Helm for deployment - Creates a <strong>single-node Kubernetes cluster</strong> with Kind for testing Helm deployments</li>
    <li>Jenkins container is configured to host CI/CD builds</li>
    <li>Kubernetes Secrets for secure credentials</li>
    <li>Trivy for security scanning</li>
</ul>

<h2>Repository Structure</h2>
<pre>
.
├── ansible/             # Ansible playbooks for Ubuntu setup
├── app/                 # Web application code (Node.js/Python/Go)
├── helm/                # Helm chart for Kubernetes deployment
├── jenkins              # CI/CD pipeline
└── README.md
</pre>

<h1>Usage Instructions</h1>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
</head>
<body>

<h1>Part 1: Linux & Ansible Setup</h1>
<h3>1. Provision Infrastructure (Ansible)</h3>
<p>Run the playbook on your Ubuntu host to install Docker, Kubernetes tools, Helm, and Jenkins:</p>
<pre>
git clone https://github.com/freedal96/DevOpsTask.git
cd ansible
ansible-playbook -i inventory.ini playbook.yaml --ask-become-pass
</pre>
<p>This Ansible playbook prepares a single-node Ubuntu environment for container orchestration and CI/CD. It was tested on WSL Ubuntu with localhost inventory, but it can be adapted to a remote host by updating the inventory.</p>

---

<h2>Inventory File</h2>

<p>The inventory defines the host for Ansible. This configuration tells Ansible to run all tasks on the local machine using a local connection.Here we use <code>localhost</code> for WSL:</p>

<pre>
[webserver]
localhost ansible_connection=local
</pre>

---

<h2>Playbook Overview</h2>

<p>The Ansible playbook installs and configures:</p>
<ul>
  <li>Docker and Docker service</li>
  <li>Kubernetes binaries: kubeadm, kubelet, kubectl</li>
  <li>Kind for a single-node Kubernetes cluster</li>
  <li>Helm for Kubernetes package management</li>
  <li>Jenkins container with Docker access for CI/CD</li>
  <li>Non-root DevOps user with sudo and SSH key</li>
  <li>Firewall configuration (UFW)</li>
  <li>Swap disabling for Kubernetes</li>
  <li>Test NGINX container deployment</li>
</ul>

---

<h2>Playbook Breakdown</h2>
<ul>
<li>hosts: webserver — target the localhost group in the inventory.</li>
<li>become: yes — ensures all commands run with sudo privileges.</li>
<li>gather_facts: yes — collects system information for conditional logic or configuration.</li>
</ul>
<pre>
- name: Setup Ubuntu for DevOps (Single Node)
  hosts: webserver
  become: yes
  gather_facts: yes
</pre>

<ul>
<li>Stores usernames, paths, and versions to make the playbook reusable and maintainable</li>
</ul>
<pre>
  vars:
    devops_user: devops
    kube_version: v1.27.4
    kube_bin_path: /usr/local/bin
    ssh_pubkey_path: "/home/xxxxx/.ssh/id_rsa.pub"
    kind_version: v0.26.0
    kind_node_image: kindest/node:v1.34.0
</pre>
<ul>
</ul>
<h2>Steps Explained</h2>
<h4>1. Logging start of playbook</h4>
Provides visual feedback in Jenkins or CLI logs
<pre>
    - name: Log start of playbook
      ansible.builtin.debug:
        msg: "Starting Ubuntu DevOps setup..."
</pre>

<h4>2. Update and upgrade Ubuntu packages</h4>
Ensures all packages are up-to-date before installing Docker or Kubernetes
<pre>
    - name: Update apt packages
      ansible.builtin.apt:
        update_cache: yes
        upgrade: dist
</pre>
<h4>3. Install required packages including Docker </h4>
Installs Docker, firewall (UFW), and basic system utilities for container orchestration.
<pre>
    - name: Install required packages including Docker
      ansible.builtin.apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - software-properties-common
          - ufw
          - docker.io
        state: present
        update_cache: yes
</pre>
<h4>4. Enable Docker service </h4>
Starts Docker and ensures it starts on boot.
<pre>
    - name: Enable Docker service
      ansible.builtin.systemd:
        name: docker
        enabled: yes
        state: started
</pre>
<h4> 5. Download Kubernetes binaries and kind for single-node cluster </h4>
Installs kubeadm, kubelet, kubectl.
<pre>
    - name: Download Kubernetes binaries
      ansible.builtin.get_url:
        url: "https://dl.k8s.io/release/{{ kube_version }}/bin/linux/amd64/{{ item }}"
        dest: "{{ kube_bin_path }}/{{ item }}"
        mode: '0755'
      loop:
        - kubeadm
        - kubelet
        - kubectl
</pre>
Downloads kind for creating a single-node Kubernetes cluster:
<pre>
    - name: Download kind binary
      ansible.builtin.get_url:
        url: "https://kind.sigs.k8s.io/dl/{{ kind_version }}/kind-linux-amd64"
        dest: "{{ kube_bin_path }}/kind"
        mode: '0755'
</pre>
<pre>
    - name: Create Kind cluster
      ansible.builtin.shell: >
        kind create cluster --name devops-cluster --image {{ kind_node_image }}
      args:
        creates: /root/.kube/config
</pre>
Initializes a single-node Kubernetes cluster for testing Helm and deployments.
<h4>6. Install Helm </h4>
Installs Helm for Kubernetes package management.
<pre>
    - name: Install Helm using official script
      ansible.builtin.shell: |
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      args:
        creates: /usr/local/bin/helm
</pre>
<h4>7. Run Jenkins container with Docker socket </h4>
Starts Jenkins inside a Docker container with access to host Docker, enabling CI/CD builds from inside Jenkins.
<pre>
    - name: Run Jenkins container with Docker access
      community.docker.docker_container:
        name: jenkins
        image: jenkins/jenkins:lts
        state: started
        restart_policy: always
        privileged: yes
        published_ports:
          - "8081:8080"
          - "50000:50000"
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
          - /usr/bin/docker:/usr/bin/docker
          - jenkins_home:/var/jenkins_home
</pre>
Install helm inside Jenkins docker.
<pre>
    - name: Install Helm inside Jenkins container
      ansible.builtin.shell: |
        docker exec --user root jenkins bash -c "
          apt-get update -y &&
          apt-get install -y curl tar apt-transport-https ca-certificates gnupg lsb-release &&
          curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz -o /tmp/helm.tar.gz &&
          tar -zxvf /tmp/helm.tar.gz -C /tmp &&
          mv /tmp/linux-amd64/helm /usr/local/bin/helm &&
          chmod +x /usr/local/bin/helm &&
          helm version
        "
</pre>
<h4>8. Create non-root user and add SSH key </h4>
Creates a non-root DevOps user with sudo and Docker privileges.
<pre>
    - name: Ensure devops user exists
      ansible.builtin.user:
        name: "{{ devops_user }}"
        groups: sudo,docker
        shell: /bin/bash
        create_home: yes
</pre>
Adds SSH public key for secure login.
<pre>
    - name: Add SSH public key for devops
      ansible.builtin.authorized_key:
        user: "{{ devops_user }}"
        key: "{{ lookup('file', ssh_pubkey_path) }}"
</pre>
<h4>9.Disable swap (required for Kubernetes) </h4>
Ensures Kubernetes works correctly by disabling swap.
<pre>
    - name: Disable swap immediately
      ansible.builtin.command: swapoff -a

    - name: Disable swap permanently
      ansible.builtin.replace:
        path: /etc/fstab
        regexp: '^(.+\sswap\s.+)$'
        replace: '# \1'
</pre>
<h4>10.Configure UFW firewall </h4>
Sets secure default firewall policy but allows common ports.
<pre>
    - name: Set default UFW policy to deny incoming
      ansible.builtin.ufw:
        state: enabled
        direction: incoming
        policy: deny

    - name: Allow SSH, HTTP, HTTPS, NodePorts
      ansible.builtin.ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - 22
        - 80
        - 443
        - "30000:32767"
</pre>
<h4>11.Deploy test NGINX container </h4>
Verifies Docker and container orchestration are working.
<pre>
    - name: Deploy test NGINX container
      community.docker.docker_container:
        name: test-nginx
        image: nginx:latest
        state: started
        restart_policy: always
        published_ports:
          - "8080:80"
</pre>
<h4> 12.Log completion </h4>
Confirms all tasks completed successfully.
<pre>
    - name: Log completion
      ansible.builtin.debug:
        msg: "Ubuntu DevOps setup completed successfully!"
</pre>

---

<h2>Execution Steps</h2>

<ol>
  <li>Clone the repository:</li>
  <pre>git clone https://github.com/freedal96/DevOpsTask.git</pre>

  <li>Navigate to Ansible folder:</li>
  <pre>cd DevOpsTask/ansible</pre>

  <li>Run the playbook:</li>
  <pre>ansible-playbook -i inventory.ini playbook.yaml --ask-become-pass</pre>

  <li>Verify Docker and NGINX container:</li>
  <pre>docker ps</pre>

  <li>Verify Kind cluster:</li>
  <pre>kubectl cluster-info --context kind-devops-cluster</pre>
</ol>

---

<h2>Explanation of Ansible Key Steps</h2>

<table>
<tr>
<th>Requirement</th>
<th>Implementation</th>
</tr>
<tr>
<td>Update environment</td>
<td>apt module with update_cache and upgrade: dist</td>
</tr>
<tr>
<td>Install Docker, Kubernetes, Helm, Jenkins</td>
<td>Docker via apt, Kubernetes binaries via get_url, Helm via script, Jenkins as Docker container</td>
</tr>
<tr>
<td>Non-root user with SSH</td>
<td>user and authorized_key modules</td>
</tr>
<tr>
<td>UFW firewall</td>
<td>ufw module to set default deny and allow required ports</td>
</tr>
<tr>
<td>Disable swap</td>
<td>command swapoff and modify /etc/fstab</td>
</tr>
<tr>
<td>Deploy test container</td>
<td>community.docker.docker_container module with NGINX image</td>
</tr>
</table>

---
<h1>Part 2: Docker — Containerization</h1>
<h2>Dockerfile Summary</h2>

<table>
  <thead>
    <tr>
      <th>Section</th>
      <th>Purpose</th>
      <th>Key Notes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Stage 1 – Build</strong></td>
      <td>Compile dependencies into Python wheels</td>
      <td>Uses <code>pip wheel</code> to prebuild dependencies for faster installs and isolated builds</td>
    </tr>
    <tr>
      <td><strong>Stage 2 – Runtime</strong></td>
      <td>Prepare lightweight app runtime image</td>
      <td>Copies prebuilt wheels, installs without cache, and copies source code for smaller image size</td>
    </tr>
    <tr>
      <td><strong>ENV / EXPOSE</strong></td>
      <td>Define environment variables and container port</td>
      <td>Sets <code>PORT=8000</code> and exposes port <code>8000</code> for application access</td>
    </tr>
    <tr>
      <td><strong>HEALTHCHECK</strong></td>
      <td>Validate container health periodically</td>
      <td>Runs <code>curl http://localhost:8000/health</code> every 10s, marking unhealthy containers automatically</td>
    </tr>
    <tr>
      <td><strong>CMD</strong></td>
      <td>Run application with Gunicorn</td>
      <td>Executes <code>gunicorn --bind 0.0.0.0:8000 app:app --workers 2</code> for a production-ready WSGI server</td>
    </tr>
    <tr>
      <td><strong>Optimization</strong></td>
      <td>Reduce image size and improve build speed</td>
      <td>Uses <code>python:3.10-slim</code>, no cache, and multi-stage build to minimize the final image footprint (~150MB)</td>
    </tr>
  </tbody>
</table>

</body>
</html>


<h1>Part 3: Jenkins — CI/CD Pipeline , Helm — Deployment</h1>
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

<h1>Part 4: Secrets Management — Secure Configuration</h1>
<h4>Secrets Management Overview</h4>

<p>This project ensures that all sensitive information is securely managed and never hardcoded in the source code or Docker images.</p>

<h4>1. DockerHub Credentials</h4>
<ul>
  <li>Stored securely in <strong>Jenkins Credentials Manager</strong> (type: <code>Username/Password</code>).</li>
  <li>Injected dynamically during the pipeline execution using Jenkins' <code>withCredentials</code> block.</li>
  <li>Used to authenticate and push Docker images to DockerHub within the CI/CD pipeline.</li>
</ul>

<pre><code class="language-groovy">
withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
    sh '''
        echo $DH_PASS | docker login -u $DH_USER --password-stdin
        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
    '''
}
</code></pre>

<h4>2. Application Secrets</h4>
<ul>
  <li>Managed as <strong>Kubernetes Secrets</strong> (for example: <code>webapp-secrets</code>).</li>
  <li>These secrets store application-level credentials such as database URLs, API keys, or tokens.</li>
  <li>Secrets are automatically injected into application Pods as environment variables through Helm templates.</li>
</ul>

<pre><code class="language-yaml">
envFrom:
  - secretRef:
      name: {{ .Values.secrets.appSecretName | default "webapp-secrets" }}
</code></pre>

<h4>3️. Helm Integration</h4>
<ul>
  <li>Helm dynamically references secrets defined in <code>values.yaml</code> or provided as Jenkins parameters.</li>
  <li>This allows per-environment secret customization without exposing sensitive data in source control.</li>
  <li>Ensures a <strong>secure, parameterized, and environment-specific</strong> deployment workflow.</li>
</ul>

<pre><code class="language-yaml">
# values.yaml
secrets:
  appSecretName: webapp-secrets
  dockerRegistry: my-dockerhub-secret
</code></pre>

<h3>✅ Summary</h3>

<p>
All <strong>DockerHub</strong> and <strong>application secrets</strong> are stored securely using native mechanisms — 
<strong>Jenkins Credentials</strong> and <strong>Kubernetes Secrets</strong> — and injected safely at runtime via 
<strong>Helm templates</strong>. This approach ensures secrets are never exposed in source code or Docker images.
</p>

<p>
For <strong>production-ready deployments</strong>, it is recommended to externalize secret management to enterprise-grade 
secret stores, such as:
</p>

<ul>
  <li><strong>HashiCorp Vault</strong> — for centralized, fine-grained secret management and dynamic secret generation.</li>
  <li><strong>Azure Key Vault</strong> — when running on Microsoft Azure, to securely store API keys, certificates, and connection strings.</li>
  <li><strong>AWS Secrets Manager</strong> or <strong>Google Secret Manager</strong> — for secure integration with respective cloud-native environments.</li>
</ul>

<p>
By integrating these cloud-based vaults or HashiCorp Vault, the pipeline achieves:
</p>

<ul>
  <li>End-to-end secret rotation and auditability.</li>
  <li>Centralized policy management across multiple environments.</li>
  <li>Compliance with production security standards (SOC2, ISO 27001, etc.).</li>
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

</body>
</html>
