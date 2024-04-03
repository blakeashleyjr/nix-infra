# Installation Guide

## Preparing Your Environment

Use the bootstrap.sh script to get the machine online by pasting it in via pi-kvm.

```
sudo nano bootstrap.sh // paste in the script
sudo chmod +x bootstrap.sh
sudo bash bootstrap.sh hv-2
```

## Test SSH Access

Ensure the system can be accessed via SSH.

**SSH from Workstation**  
   ```
   ssh-keygen -R 10.173.5.70
   ssh root@10.173.5.70
   ```

## Install the system with Ansible

```
ansible-playbook install-system.yaml -i hosts.yaml -e "target_host={{ hostname }}"
```