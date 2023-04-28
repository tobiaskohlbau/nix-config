NIXADDR ?= unset
NIXUSER ?= tobiaskohlbau

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

switch:
	sudo nixos-rebuild switch --flake ".#vm-aarch64-utm"

test:
	sudo nixos-rebuild test --flake ".#vm-aarch64-utm"

vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	ssh $(NIXUSER)@$(NIXADDR) "sudo reboot;"

vm/copy:
	rsync -av \
		--exclude='.git/' \
		--rsync-path="sudo rsync" \
		${MAKEFILE_DIR}/ ${NIXUSER}@${NIXADDR}:/nix-config

vm/switch:
	ssh $(NIXUSER)@$(NIXADDR) "sudo nixos-rebuild switch --flake \"/nix-config#vm-aarch64-utm\""
