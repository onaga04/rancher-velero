# rancher-velero

An Ansible-based automation framework for backing up and restoring Kubernetes workloads using [Velero](https://velero.io/), purpose-built for **RKE1 to RKE2 migration workflows** on Azure and vSphere environments.

This tooling was developed from real-world enterprise migration work and is designed to reduce manual effort, minimize downtime risk, and enforce consistent backup/restore procedures across Kubernetes clusters managed by [SUSE Rancher](https://www.rancher.com/).

---

## Why This Exists

Migrating from RKE1 to RKE2 is one of the most common — and risky — infrastructure transitions facing Kubernetes teams today. RKE1 reached end-of-life, and organizations running Rancher-managed clusters must migrate to RKE2 to maintain security support and compatibility.

A reliable, automated backup and restore process is critical to this migration. Without it, teams face:

- Manual, error-prone Velero installation steps across source and target clusters
- Inconsistent snapshot class and storage class configuration between environments
- No repeatable process for validating backups before cutover
- Significant recovery time if something goes wrong during migration

This framework automates the entire Velero backup and restore lifecycle — from installation through execution — so teams can migrate with confidence.

---

## Features

- **Interactive task runner** — select individual steps via a simple CLI menu rather than running full playbooks blindly
- **Cloud-aware installation** — automatically detects Azure vs. non-Azure hosts and applies the appropriate Azure CLI setup
- **Modular Ansible architecture** — each task is isolated and independently executable via tags, making it easy to re-run individual steps without repeating the full workflow
- **Source → Target cluster model** — backup playbook runs against the source (RKE1) cluster; restore playbook runs against the target (RKE2) cluster
- **Azure Blob Storage backend** — Velero is configured to use Azure Blob Storage for backup storage, with snapshot class setup included
- **Storage class and ConfigMap migration** — handles the reconfiguration differences between RKE1 and RKE2 storage classes on the target cluster
- **Dependency bootstrapping** — automatically installs `python3-pip` and Ansible if not present on the control node

---

## Architecture

```
rancher-velero/
├── run_backup.sh              # Interactive backup task runner
├── run_restore.sh             # Interactive restore task runner
├── inventory.ini              # Ansible inventory (source + target clusters)
└── ansible/
    ├── velero-backup.yaml     # Backup playbook (runs on source_cluster)
    ├── velero-restore.yaml    # Restore playbook (runs on target_cluster)
    └── tasks/
        ├── common/
        │   ├── install_azure.yml           # Azure CLI install (Azure hosts)
        │   ├── install_azure_full.yaml     # Azure CLI install (non-Azure hosts)
        │   ├── azure_login.yml             # Azure authentication
        │   ├── install_velero_cli.yml      # Velero CLI installation
        │   └── install_velero.yml          # Velero server installation
        ├── backup/
        │   ├── setup_snapshotclass.yml     # VolumeSnapshotClass configuration
        │   └── create_backup.yml           # Execute Velero backup
        └── restore/
            ├── setup_storageclass.yml      # StorageClass setup on target cluster
            ├── setup_configmap.yml         # ConfigMap migration configuration
            └── create_restore.yml          # Execute Velero restore
```

---

## Prerequisites

- Ubuntu/Debian control node (the scripts will install `python3-pip` and `ansible` if missing)
- `kubectl` configured for both source and target clusters
- Azure subscription with Blob Storage for Velero backend
- KUBECONFIG files for source (RKE1) and target (RKE2) clusters
- SUSE Rancher managing both clusters (RKE1 source, RKE2 target)

---

## Configuration

### 1. Update `inventory.ini`

Define your source (RKE1) and target (RKE2) cluster hosts:

```ini
[source_cluster]
<source-node-ip> ansible_user=<user> ansible_ssh_private_key_file=<path-to-key>

[target_cluster]
<target-node-ip> ansible_user=<user> ansible_ssh_private_key_file=<path-to-key>
```

### 2. Update `ansible/group_vars/all.yaml`

Set your environment variables:

```yaml
kubeconfig_path: /path/to/your/kubeconfig
cloud_provider: azure        # Set to 'azure' or other
velero_version: v1.13.0      # Velero version to install
backup_name: my-rke1-backup  # Name for your Velero backup
restore_name: my-rke2-restore
azure_storage_account: <your-storage-account>
azure_storage_container: <your-blob-container>
azure_resource_group: <your-resource-group>
```

---

## Usage

### Backup (Source RKE1 Cluster)

```bash
chmod +x run_backup.sh
./run_backup.sh
```

You will be presented with a menu:

```
Available tasks:
 1) Install Azure CLI on Azure hosts
 2) Install full Azure CLI setup on non Azure hosts
 3) Log in to Azure
 4) Install Velero CLI
 5) Install Velero
 6) Setup snapshot class for Velero
 7) Create Velero backup
```

For a full initial setup, run tasks in order (1 or 2 → 3 → 4 → 5 → 6 → 7).

### Restore (Target RKE2 Cluster)

```bash
chmod +x run_restore.sh
./run_restore.sh
```

Menu:

```
Available tasks:
 1) Install Azure CLI on Azure hosts
 2) Install full Azure CLI setup on non Azure hosts
 3) Log in to Azure
 4) Install Velero CLI
 5) Install Velero
 6) Setup storage class
 7) Setup configmap
 8) Create Velero restore
```

For a full restore, run tasks in order (1 or 2 → 3 → 4 → 5 → 6 → 7 → 8).

---

## Migration Workflow

This framework fits into a broader RKE1 → RKE2 migration as follows:

```
1. Provision RKE2 target cluster (Rancher + Terraform/AKS/vSphere)
2. Run backup workflow on RKE1 source cluster        ← this repo
3. Validate backup in Azure Blob Storage
4. Run restore workflow on RKE2 target cluster       ← this repo
5. Validate workloads on RKE2
6. Cutover DNS / traffic
7. Decommission RKE1 cluster
```

---

## Security Considerations

- Azure credentials are handled via `az login` at runtime and are never stored in playbook variables
- Velero uses Azure Managed Identity or Service Principal — configure appropriately for your environment
- KUBECONFIG paths are passed via environment variables, not hardcoded
- All Ansible tasks run with `become: yes` — ensure your SSH user has appropriate sudo privileges
- Snapshot classes and storage classes are explicitly configured to avoid data loss during cross-cluster restore

---

## Tested Environments

| Component | Version |
|-----------|---------|
| RKE1 (source) | v1.5.x |
| RKE2 (target) | v1.28.x+ |
| Velero | v1.13.x |
| Ansible | 2.15+ |
| Azure CLI | 2.x |
| SUSE Rancher | 2.7 / 2.8 |

---

## Contributing

Contributions, issues, and feature requests are welcome. If you're working on an RKE1 → RKE2 migration and have encountered edge cases this tooling doesn't handle, please open an issue or submit a PR.

Areas where contributions would be especially valuable:
- vSphere-specific snapshot class configurations
- Support for AWS S3 and GCP GCS as Velero backends
- Automated backup validation (pre-restore verification)
- Support for air-gapped / disconnected environments

---

## Related Resources

- [Velero Documentation](https://velero.io/docs/)
- [SUSE Rancher RKE2 Migration Guide](https://docs.rke2.io/)
- [CNCF Velero Project](https://www.cncf.io/projects/velero/)
- [Azure Blob Storage Velero Plugin](https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
