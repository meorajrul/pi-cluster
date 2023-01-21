GPG_RECIPIENT=vault@ansible

.PHONY: default
default: clean

.PHONY: prepare-ansible
prepare-ansible: install-ansible-requirements gpg-init ~/.vault/vault_passphrase.gpg ansible-credentials

.PHONY: clean
clean: k3s-reset external-services-reset

.PHONY: init
init: os-upgrade gateway-setup nodes-setup external-services configure-os-backup k3s-install k3s-bootstrap

.PHONY: install-ansible-requirements
install-ansible-requirements: # install Ansible requirements
	cd ansible && ansible-galaxy install -r requirements.yml

.PHONY: install-ansible-requirements-force
install-ansible-requirements-force: # install Ansible requirements
	cd ansible && ansible-galaxy install -r requirements.yml --force

.PHONY: gpg-init
gpg-init:
	gpg --quick-generate-key ${GPG_RECIPIENT}

~/.vault/vault_passphrase.gpg: # Ansible vault gpg password
	mkdir -p ~/.vault
	pwgen -n 71 -C | head -n1 | gpg --armor --recipient ${GPG_RECIPIENT} -e -o ~/.vault/vault_passphrase.gpg

.PHONY: ansible-credentials
ansible-credentials: ~/.vault/vault_passphrase.gpg install-ansible-requirements
	cd ansible && ansible-playbook create_vault_credentials.yml

.PHONY: os-upgrade
os-upgrade:
	cd ansible && ansible-playbook update.yml

.PHONY: gateway-setup
gateway-setup:
	cd ansible && ansible-playbook setup_picluster.yml --tags "gateway"

.PHONY: nodes-setup
nodes-setup:
	cd ansible && ansible-playbook setup_picluster.yml --tags "nodes"

.PHONY: external-services
external-services:
	cd ansible && ansible-playbook external_services.yml

.PHONY: configure-os-backup
configure-os-backup:
	cd ansible && ansible-playbook backup_configuration.yml

.PHONY: os-backup
os-backup:
	cd ansible && ansible -b -m shell -a 'systemctl start restic-backup' raspberrypi

.PHONY: k3s-install
k3s-install:
	cd ansible && ansible-playbook k3s_install.yml

.PHONY: k3s-bootstrap
k3s-bootstrap:
	cd ansible && ansible-playbook k3s_bootstrap.yml

.PHONY: k3s-reset
k3s-reset:
	cd ansible && ansible-playbook k3s_reset.yml

.PHONY: external-services-reset
external-services-reset:
	cd ansible && ansible-playbook reset_external_services.yml
