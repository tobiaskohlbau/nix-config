NIXADDR ?= unset
NIXUSER ?= tobiaskohlbau
NIXCONFIG ?= unset
GITHUB_TOKEN ?= unset

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

switch:
	sudo nixos-rebuild switch --flake ".#$(NIXCONFIG)"

test:
	sudo nixos-rebuild test --flake ".#$(NIXCONFIG)"

vm/bootstrap:
	NIXUSER=root $(MAKE) machine/copy
	NIXUSER=root NIXCONFIG=vm-aarch64-utm $(MAKE) machine/switch
	ssh $(NIXUSER)@$(NIXADDR) "sudo reboot;"

pc/bootstrap:
	NIXUSER=root $(MAKE) machine/copy
	NIXUSER=root NIXCONFIG=pc-x86_64 $(MAKE) machine/switch
	ssh $(NIXUSER)@$(NIXADDR) "sudo reboot;"

machine/copy:
	rsync -av \
		--exclude='.git/' \
		--rsync-path="sudo rsync" \
		${MAKEFILE_DIR}/ ${NIXUSER}@${NIXADDR}:/nix-config

machine/switch:
	ssh $(NIXUSER)@$(NIXADDR) "NIX_CONFIG=\"extra-access-tokens = github.com=$(GITHUB_TOKEN)\" sudo -E nixos-rebuild switch --flake \"/nix-config#$(NIXCONFIG)\""
