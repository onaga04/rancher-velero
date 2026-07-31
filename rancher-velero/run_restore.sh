#!/bin/bash
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

if ! command -v az &> /dev/null; then
    echo "Azure CLI not found. Installing now..."
    curl -sL https://aka.ms/InstallAzureCli | bash || {
        echo "Error: Failed to install Azure CLI"
        exit 1
    }
    echo "Azure CLI installed successfully."
else
    echo "Azure CLI is already installed."
fi

if ! ansible-galaxy collection list | grep -q "kubernetes.core"; then
    echo "kubernetes.core collection not found. Installing now..."
    ansible-galaxy collection install kubernetes.core || {
        echo "Error: Failed to install kubernetes.core collection"
        exit 1
    }
    echo "kubernetes.core collection installed successfully."
else
    echo "kubernetes.core collection is already present."
fi

if ! command -v velero &> /dev/null; then
    echo "Velero CLI not found. Installing now..."
    VELERO_VERSION="v1.15.2"
    curl -sL "https://github.com{VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz" | tar -xzf - --strip-components=1 -C /tmp
    sudo mv /tmp/velero /usr/local/bin/velero || {
      echo "Error: Failed to install Velero CLI"
      exit 1
    }
    rm -rf /tmp/velero-${VELERO_VERSION}-linux-amd64*
    echo "Velero CLI (${VELERO_VERSION}) installed successfully."
else
    INSTALLED_VER=$(velero version --client-only | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
    echo "Velero CLI is already installed = $INSTALLED_VER"
fi


export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Define available tasks
declare -a tasks=(
  "Log in to Azure"
  "Install Velero for CSI Backup"
  "Install Velero for FSBackup"
  "Setup configmap"
  "Velero CRDs restore"
  "Velero cluster scoped dependencies restore"
  "Velero namespaced resources restore"
  "Assign Namespace to Rancher Project"
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
