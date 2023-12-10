{ pkgs, ... }: {
  # https://github.com/Mic92/nixos-shell/#readme
  boot.kernelPackages = pkgs.linuxPackages_latest;
  system.stateVersion = "22.05";
  users.extraUsers.unprivileged = {
    isNormalUser = true;
    initialPassword = "";
    group = "wheel";
    extraGroups = [ "docker" "libvirt" "networkmanager" ];
    home = builtins.getEnv "HOME";
  };
  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
  nix.settings.experimental-features = [ "flakes" "nix-command" ];
  services.openssh.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 50022; guest.port = 22;   }
    { from = "host"; host.port = 57011; guest.port = 7011; } # Blockchain Explorer
    { from = "host"; host.port = 58801; guest.port = 8801; } # Fablo Rest
  ];
  virtualisation.qemu.networkingOptions = [
    "-nic bridge,br=virbr0,model=virtio-net-pci,mac=02:00:00:01:01:01,helper=/usr/libexec/qemu-bridge-helper"
  ];
  environment.systemPackages = with pkgs; [
    # https://search.nixos.org/packages
    git
    git-branchless
    magic-wormhole
  ];
  # ssh -X -o UserKnownHostsFile=/dev/null -o "StrictHostKeyChecking no" root@localhost -p 50022
  services.openssh.settings.X11Forwarding = true;
}
