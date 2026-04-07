#!/bin/bash

CLOUD_PROVIDER="RKE1"

if ! dpkg -l | grep -q python3-pip; then
    echo "python3-pip not found. Installing now..."
    sudo apt update
    sudo apt install -y python3-pip || {
        echo "Error: Failed to install python3-pip"
        exit 1
    }
    echo "python3-pip installed successfully."
else
    echo "python3-pip is already installed."
fi

if ! command -v ansible &> /dev/null; then
    echo "Ansible not found. Installing via pip3 now..."
    pip3 install ansible || {
        echo "Error: Failed to install Ansible"
        exit 1
    }
    echo "Ansible installed successfully."
else
    echo "Ansible is already installed."
fi

if [ "$CLOUD_PROVIDER" == "AKS" ]; then
  export KUBECONFIG=/var/lib/kubelet/kubeconfig
elif [ "$CLOUD_PROVIDER" == "RKE2" ]; then
  export PATH=$PATH:/var/lib/rancher/rke2/bin
  export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
elif [ "$CLOUD_PROVIDER" == "RKE1" ]; then
  export KUBECONFIG=/etc/kubernetes/ssl/kubecfg-kube-node.yaml
  K8S_VERSION=$(docker ps | grep hyperkube | head -n 1 | awk -F: '{print $2}' | awk '{print $1}' | cut -d'-' -f1) 
  curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
else
    echo "Unknown Cloud Provider: $CLOUD_PROVIDER"
fi

# Define available tasks
declare -a tasks=(
  "Install Azure CLI on Azure hosts"
  "Install full Azure CLI setup on non Azure hosts"
  "Log in to Azure"
  "Install Velero CLI"
  "Install Velero"
  "Setup configmap"
  "Velero CRDs restore"
  "Velero cluster scoped dependencies restore"
  "Velero namespaced resources restore"
)

# Function to display tasks
show_tasks() {
  echo "Available tasks:"
  for i in "${!tasks[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${tasks[$i]}"
  done
  echo
  echo "Enter the number of the task to run."
  echo "[c] Cancel"
}

# Loop to select tasks
while true; do
  show_tasks
  read -rp "Choice: " choice

  case "$choice" in
    [0-9]*)
      if (( choice >= 1 && choice <= ${#tasks[@]} )); then
        task_name="${tasks[$((choice-1))]}"
        echo "Running: $task_name"
        ansible-playbook -i inventory.ini ansible/velero-restore.yaml --tags "$(echo "$task_name" | tr ' ' '_')" -vvvv || {
          echo "Error running $task_name"
        }
      else
        echo "Invalid task number."
      fi
      ;;
    c|C)
      echo "Cancelled."
      exit 0
      ;;
    *)
      echo "Invalid choice."
      ;;
  esac
done
