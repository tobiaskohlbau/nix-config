NIXADDR ?= unset
NIXUSER ?= tobiaskohlbau
NIXCONFIG ?= unset
GITHUB_TOKEN ?= unset
DISK_NAME ?= unset
DISK_SUFFIX ?=
OVERRIDES ?=

MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

switch:
ifeq ($(shell uname), Darwin)
	NIXPKGS_ALLOW_UNFREE=1 nix build --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXCONFIG}.system"
	./result/sw/bin/darwin-rebuild switch --flake "$$(pwd)#${NIXCONFIG}"
else
	sudo nixos-rebuild switch --flake ".#$(NIXCONFIG)" ${OVERRIDES}
endif

test:
	sudo nixos-rebuild test --flake ".#$(NIXCONFIG)"

installer:
	ssh $(SSH_OPTIONS) root@$(NIXADDR) " \
		parted /dev/$(DISK_NAME) -s -- mklabel gpt \
		mkpart primary 512MB -8GB \
		mkpart primary linux-swap -8GB 100\% \
		mkpart ESP fat32 1MB 512MB \
		set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/$(DISK_NAME)$(DISK_SUFFIX)1; \
		mkswap -L swap /dev/$(DISK_NAME)$(DISK_SUFFIX)2; \
		mkfs.fat -F 32 -n boot /dev/$(DISK_NAME)$(DISK_SUFFIX)3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixVersions.latest;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
  			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
			environment.systemPackages = with pkgs; [\n \
				git\n \
			]; \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && reboot; \
	"

# Assume disk name to be vda and shutdown after installation in order to remove the disk before starting again.
vm/installer:
	ssh $(SSH_OPTIONS) root@$(NIXADDR) " \
		parted /dev/vda -s -- mklabel gpt \
		mkpart primary 512MB -8GB \
		mkpart primary linux-swap -8GB 100\% \
		mkpart ESP fat32 1MB 512MB \
		set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/vda1; \
		mkswap -L swap /dev/vda2; \
		mkfs.fat -F 32 -n boot /dev/vda3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixVersions.latest;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
  			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			environment.systemPackages = [ pkgs.git ];\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && shutdown -h now; \
	"

bootstrap:
	NIXUSER=root $(MAKE) machine/copy
	NIXUSER=root $(MAKE) machine/switch
	ssh $(SSH_OPTIONS) $(NIXUSER)@$(NIXADDR) "sudo reboot;"

machine/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='.git/' \
		--rsync-path="sudo rsync" \
		${MAKEFILE_DIR}/ ${NIXUSER}@${NIXADDR}:/nix-config

machine/switch:
	ssh $(SSH_OPTIONS) $(NIXUSER)@$(NIXADDR) "printf \"machine github.com\nlogin tobiaskohlbau\npassword $(GITHUB_TOKEN)\" > /root/.netrc && sudo -E nixos-rebuild switch --flake \"/nix-config#$(NIXCONFIG)\" && rm /root/.netrc"
