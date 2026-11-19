# Welcome To My Homelab

This is my personal infrastructure lab running on a Lenovo ThinkCentre M720q, built from scratch as part of a career change into the world of Infrastructure Engineering! Everything here is manually configured - no copy & pasting of code, no blind tutorial following. If it's in this repo, I typed it and understand it. The goal is simple - build a homelab that is both functional and a learning experience. I need to learn, use, break and fix the tools used every day as an Infrastructure engineer. 

## Hardware

| Component | Detail |
|---|---|
| Host | Lenovo ThinkCentre M720q Intel I5 8th Gen|
| Hypervisor | Proxmox VE |
| Boot drive | 238GB Samsung NVMe (Proxmox OS) |
| Data drive | 1TB internal SATA SSD (data storage, passed through to VM) |
| Network | Ethernet through USB RJ45 adaptor through switch to powerline adaptor |

## VM Registry

| VM Reference | OS & Use |
|---|---|
| VM101 | Ubuntu 24 LTS|
| VM102 | *Planned* RHEL 10 Replacement for VM101 |
| VM103 | RHEL 10 Node1 for RHCSA labs |
| VM105 | RHEL 10 Node2 for RHCSA labs |
| VM106 | RHEL 10 to be used as the Prometheus & Grafana node |
| VM107 | Oracle Linux 10.2 VM to utilise Oracles Linux distro & database tooling |

# What's running

All services to be accompanied by an ADR, runbook and any incident reports.

| Service | Purpose | Status |
|---|---|---|
| Active Directory | Bare-metal Windows Server AD DC | Under Construction |
| Gitea | Private repo, to be mirrored to Github | Under Construction |
| DNS Sinkhole | PiHole DNS Sinkhole for Samsung TV | Deployed & running |
| Headscale | Self-hosted Tailscale control server | Planned |
| Fail2ban | Intrusion prevention / log monitoring | Planned |


# What's planned

This homelab is evolving alongside a structured Infrastructure Engineering learning programme. Upcoming additions mapped to career goals:

| Addition | Purpose | Skills demonstrated |
|---|---|---|
| Windows Server (bare metal) | Domain Controller & Active Directory | IAM management and Win/Linux integration. Bare metal to add networking reps | 
| Gitea & GitHub Actions CI/CD | Automated linting, testing, Docker image builds | CI/CD pipelines, automated workflows. Gitea private repo with CI pushing to GitHub Actions |
| Prometheus + Grafana | Monitoring, alerting, dashboards | Observability, metrics, alerting rules |
| OpenSCAP / CIS | Security scanning and base lining | Security hardening and auditing |
| Podman | Migrate services from Docker to Podman | Migration and maintenance of rootless containers |
| Terraform configs | Provision AWS/Azure lab resources as code | Infrastructure as Code, state management |


# Repo structure
```text
.
├── README.md
├── ansible
│   ├── playbooks/
├── docs/
│   ├── adr/
│   ├── certifications/
│   │   ├── linux+
│   │   └── RHCSA/
│   └── openshift/
├── scripts/
│   └── bash

```

## Scripts

Python and Bash automation scripts built as part of a structured learning programme. Infrastructure centred scripts in both languages to build out a toolkit to both learn and help make the management of the lab easier. Repetitive tasks should be scripted out if possible.

**Completed:**

| # | Script | What it does | Concepts |
|---|---|---|---|
| 1 | dockers_s.sh | A bash TUI to start, stop, restart multiple docker containers at once | whiptail, arrays, for loops |


## Ansible & IaC

| Category | Name | What it does |
|---|---|---|
| playbook | rhel_vm_gpg.yml | Saves ML-DSA-87 GPG key to node, upgrades all packages and ensures vim is installed |
| playbook | rhel_vm_baseline.yml | sets a basic baseline, with gpg key, vim, podman, chrony etc | 

*Note: playbooks to be refactored into roles and playbooks*

## Certifications

This homelab serves as the hands-on practice environment for the following certifications:

- **CompTIA Linux+ (XK0-006)** — passed 24th July 2026
- **Red Hat RHCSA** - passed 16th November 2026
- **AWS SAA or Azure AZ-104** — likely Jan/Feb 2027 but may be brought forward. Cert decision to be made after RHCSA and Gitea & Windows AD DC is functional.

## Rules

1. No copy & paste of code — everything is manually typed
2. Document everything 
3. break thing and notice what went wrong 
4. Keep notes of blindspots and weaknesses
5. Have fun!

## About

My name is Connor. I am transitioning from co-owning a roofing business into IT, with a particular focus on Linux Infrastructure Engineering. This homelab is where I build, break, and fix things to develop real infrastructure skills. Everything documented here is genuine learning — mistakes included.

From early 2026, my evenings and weekends have been devoted to learning the essential tools, languages, workflows and Linux skills required in order to succeed as an Infrastructure engineer, whilst gaining certifications along the way to solidify and indicate my skills. I am self-taught. My main methods of learning are practical projects using my VM's, with Claude acting as a Socratic teacher - he gives me a bearing to follow, but it is down to me to research and build what is needed. I am typically using --help/man pages, google search results, youtube videos and official documentation for the language/tool I am trying to use. I specifically request Claude to not give me the answer straight away, but rather make me ask the questions in order for me to come to the answer myself. Whilst frustrating at times, the frustration is coming from a place of pushing my knowledge and my limits. 
