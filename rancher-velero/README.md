
---

 

## Architecture

 

```

rancher-velero/

├── run_backup.sh              # Interactive backup task runner script

├── run_restore.sh             # Interactive restore task runner script

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

        │   ├── setup_snapshotclass.yml             # VolumeSnapshotClass configuration

        │   ├── backup_crds.yml                     # Execute Velero backup of CRDs

        │   ├── backup_cluster_dependencies.yml     # Execute Velero backup of RBAC policies and cluster networking

        │   └── backup_namespaced_resources.yml     # Execute Velero backup of namespaced resources



        └── restore/

            ├── setup_storageclass.yml               # StorageClass setup on target cluster

            ├── setup_configmap.yml                  # ConfigMap migration configuration

            ├── restore_crds.yml                     # Execute Velero restore of CRDs

            ├── restore_cluster_dependencies.yml     # Execute Velero restore of RBAC policies and cluster networking

            └── restore_namespaced_resources.yml     # Execute Velero restore of namespaced resources
