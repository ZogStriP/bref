{ d, p, hm, hostname, pkgs, ... } : let
  username     = "zogstrip";
  name         = "Régis Hanol";
  email        = "regis@hanol.fr";
  persist      = "/persist";
  stateVersion = "26.11";
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

    home.packages = with pkgs; [
      bluetui
      devenv
      ffmpeg
      impala
      wget
      wiremix
    ];

    programs = {
      bash.enable = true;
      bash.historyControl = [ "ignoreboth" ];

      bat.enable = true;

      btop.enable = true;
      btop.settings = {
        disks_filter = "/ /boot /nix /tmp/ /swap";
        proc_tree = true;
        rounded_corners = false;
        vim_keys = true;
      };

      chromium.enable = true;

      eza.enable = true;

      fastfetch.enable = true;

      fd.enable = true;

      firefox.enable = true;

      fzf.enable = true;

      gh.enable = true;

      git.enable = true;
      git.settings.user = { inherit name email; };

      jq.enable = true;

      nh.enable = true;

      mpv.enable = true;

      ripgrep.enable = true;

      ssh.enable = true;

      starship.enable = true;

      vim.enable = true;

      zoxide.enable = true;
    };
  };

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.${username} = {
    isNormalUser = true;
    hashedPassword = "";
    extraGroups = [ "video" "wheel" ];
  };

  services.btrfs.autoScrub.enable = true;
  services.fprintd.enable = true;
  services.fwupd.enable = true;
  services.getty.autologinUser = username;
  services.libinput.touchpad.naturalScrolling = true;
  services.logind.settings.Login.HandlePowerKey = "ignore";
  services.tailscale.enable = true;
  services.tlp.enable = true;

  services.udev.extraHwdb = ''
    evdev:atkbd:*
      KEYBOARD_KEY_3a=esc

    evdev:input:b0018v32ACp0006*
      KEYBOARD_KEY_100c6=reserved
  '';

  time.timeZone = "Europe/Paris";

  networking.hostName = hostname;
  networking.useNetworkd = true;
  networking.wireless.iwd.enable = true;

  hardware.acpilight.enable = true;
  hardware.bluetooth.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  zramSwap.enable = true;

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
