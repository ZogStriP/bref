{ d, p, hm, hostname, ... } : let
  username     = "zogstrip";
  persist      = "/persist";
  stateVersion = "26.05";
in {
  imports = [
    d.nixosModules.disko
    p.nixosModules.preservation
    hm.nixosModules.home-manager
  ];

  system.stateVersion = stateVersion;

  home-manager.users.${username} = {
    home.stateVersion = stateVersion;

    home.shellAliases = {
      ".."  = "cd ..";
      "..." = "cd ../..";
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  time.timeZone = "Europe/Paris";

  networking.hostName = hostname;

  preservation.enable = true;
  preservation.preserveAt.${persist} = {
    directories = [
      "/var/lib/nixos"
    ];
    
    files = [
      { file = "/etc/machine-id"; inInitrd = true; }
    ];
  };

  fileSystems.${persist}.neededForBoot = true;

  disko.devices = {
    disk.nvme = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "luks";
              settings.allowDiscards = true;
              settings.bypassWorkqueues = true;
              content = {
                type = "btrfs";
                subvolumes = {
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "noatime" ];
                  };
                  "@persist" = {
                    mountpoint = persist;
                    mountOptions = [ "noatime" ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [ "size=128M" ];
      };
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [ "size=4G" ];
      };
    };
  };

  boot = {
    initrd.systemd.enable = true;

    loader = {
      timeout = 0;

      systemd-boot = {
        enable = true;
        editor = false;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
