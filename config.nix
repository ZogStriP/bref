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
      "ff"  = "fastfetch";
    };

    programs = {
      bash.enable = true;
      bat.enable = true;
      btop.enable = true;
      eza.enable = true;
      fastfetch.enable = true;
      fd.enable = true;
      fzf.enable = true;
      gh.enable = true;
      git.enable = true;
      jq.enable = true;
      nh.enable = true;
      ripgrep.enable = true;
      ssh.enable = true;
      starship.enable = true;
      vim.enable = true;
      zoxide.enable = true;
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    hashedPassword = "";
    extraGroups = [ "wheel" ];
  };

  services.getty.autologinUser = username;
  services.btrfs.autoScrub.enable = true;

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
                extraArgs = [ "--force" "--checksum" "xxhash" ];
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
        mountOptions = [ "size=128M" "mode=0755" ];
      };
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [ "size=4G" "mode=1777" ];
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
  nixpkgs.config.allowUnfree = true;
}
