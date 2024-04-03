# Installation Guide

## Preparing Your Environment

Each system has a {hostname}-bootstrap.sh script written for that machine specifically to stand it up and get ssh access. Use pikvm to paste the script in, make it executable, and run it from the installer.

## Test SSH Access

Ensure the system can be accessed via SSH.

**SSH from Workstation**  
   ```
   ssh-keygen -R 10.173.5.70
   ssh root@10.173.5.70
   ```

## Run Ansible Playbook to install system, reboot, and apply flake



## Pipeline

- [ ] Pipeline checks for updates every hour or on a commit, builds the flake for all hosts when there is an update
- [ ] Use Age-nix to manage secrets, create a key for each server (backup in Bitwarden)
- [ ] Ansible copies flake over, deploys the update (may use Nix default stuff here)

- [ ] After successful deploy, delete everything but the lock file
- [ ] Every hour, check the lock to see if it is different than the one in the repo
  - This is to handle workstations and other devices that may not be online all the time
- [ ] If different, deploy the flake, delete the lock, repeat.