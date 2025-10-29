#!/bin/bash

# Define available tasks
declare -a tasks=(
  "Install Azure CLI on Azure hosts"
  "Install full Azure CLI setup on non-Azure hosts"
  "Log in to Azure"
  "Set KUBECONFIG"
  "Install Velero CLI"
  "Install Velero"
  "Setup snapshot class for Velero"
  "Create Velero backup"
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
        ansible-playbook -i inventory.ini ansible/velero-backup.yaml --tags "$(echo "$task_name" | tr ' ' '_')" || {
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
