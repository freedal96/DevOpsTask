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
    <li>Jenkinsfile for CI/CD</li>
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

<h2>Usage Instructions</h2>

<h3>1. Provision Infrastructure (Ansible)</h3>
<p>Run the playbook on your Ubuntu host to install Docker, Kubernetes tools, Helm, and Jenkins:</p>
<pre>
ansible-playbook -i inventory.ini playbook.yaml --ask-become-pass
</pre>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
</head>
<body>

<h1>DevOpsTask - Part 1: Linux & Ansible Setup</h1>

<p>This Ansible playbook prepares a single-node Ubuntu environment for container orchestration and CI/CD. It was tested on WSL Ubuntu with localhost inventory, but it can be adapted to a remote host by updating the inventory..</p>

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

<h2>Playbook Code Snippet</h2>

<pre>
- name: Setup Ubuntu for DevOps (Single Node)
  hosts: webserver
  become: yes
  gather_facts: yes

  vars:
    devops_user: devops
    kube_version: v1.27.4
    kube_bin_path: /usr/local/bin
    ssh_pubkey_path: "/home/andi/.ssh/id_rsa.pub"
    kind_version: v0.26.0
    kind_node_image: kindest/node:v1.34.0

  tasks:

    - name: Log start of playbook
      ansible.builtin.debug:
        msg: "Starting Ubuntu DevOps setup..."

    - name: Update apt packages
      ansible.builtin.apt:
        update_cache: yes
        upgrade: dist

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

    - name: Enable Docker service
      ansible.builtin.systemd:
        name: docker
        enabled: yes
        state: started

    - name: Download Kubernetes binaries
      ansible.builtin.get_url:
        url: "https://dl.k8s.io/release/{{ kube_version }}/bin/linux/amd64/{{ item }}"
        dest: "{{ kube_bin_path }}/{{ item }}"
        mode: '0755'
      loop:
        - kubeadm
        - kubelet
        - kubectl

    - name: Download kind binary
      ansible.builtin.get_url:
        url: "https://kind.sigs.k8s.io/dl/{{ kind_version }}/kind-linux-amd64"
        dest: "{{ kube_bin_path }}/kind"
        mode: '0755'

    - name: Create Kind cluster
      ansible.builtin.shell: >
        kind create cluster --name devops-cluster --image {{ kind_node_image }}
      args:
        creates: /root/.kube/config

    - name: Install Helm using official script
      ansible.builtin.shell: |
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      args:
        creates: /usr/local/bin/helm

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

    - name: Ensure devops user exists
      ansible.builtin.user:
        name: "{{ devops_user }}"
        groups: sudo,docker
        shell: /bin/bash
        create_home: yes

    - name: Add SSH public key for devops
      ansible.builtin.authorized_key:
        user: "{{ devops_user }}"
        key: "{{ lookup('file', ssh_pubkey_path) }}"

    - name: Disable swap immediately
      ansible.builtin.command: swapoff -a

    - name: Disable swap permanently
      ansible.builtin.replace:
        path: /etc/fstab
        regexp: '^(.+\sswap\s.+)$'
        replace: '# \1'

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

    - name: Deploy test NGINX container
      community.docker.docker_container:
        name: test-nginx
        image: nginx:latest
        state: started
        restart_policy: always
        published_ports:
          - "8080:80"

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

<h2>Explanation of Key Steps</h2>

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

<h2>Notes</h2>

<ul>
  <li>This playbook runs on <strong>WSL Ubuntu</strong> or headless Ubuntu servers.</li>
  <li>Creates a <strong>single-node Kubernetes cluster</strong> with Kind for testing Helm deployments.</li>
  <li>Jenkins container is configured to access host Docker for CI/CD builds.</li>
  <li>For production, this setup can be extended to cloud environments (AWS/GCP/Azure).</li>
</ul>

</body>
</html>




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
