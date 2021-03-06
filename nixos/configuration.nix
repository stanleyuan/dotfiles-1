{ config, pkgs, lib, ... }:
let
  meta = import ./meta.nix;
  machine-config = lib.getAttr meta.name {
    Larry = [
      {
        imports = [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix> ];
      
        boot.initrd.availableKernelModules = [ "ahci" "xhci_hcd" ];
        boot.initrd.kernelModules = [ "wl" ];
      
        boot.kernelModules = [ "kvm-intel" "wl" ];
        boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
      }
      {
        fileSystems = {
          "/" = {
            device = "/dev/disk/by-uuid/ba82dd25-a9e5-436f-ae76-4ee44d53b2c6";
            fsType = "ext4";
          };
          "/home" = {
            device = "/dev/disk/by-uuid/b27c07d0-aaf7-44a1-87e1-5a2cb30954ec";
            fsType = "ext4";
          };
        };
      }
      {
        swapDevices = [
          # TODO: set priority
          # { device = "/dev/disk/by-uuid/f0bd0438-3324-4295-9981-07015fa0af5e"; }
          { device = "/dev/disk/by-uuid/75822d9d-c5f0-495f-b089-f57d0de5246d"; }
        ];
      }
      {
        boot.loader.grub = {
          enable = true;
          version = 2;
          device = "/dev/sda";
          extraEntries = ''
            menuentry 'Gentoo' {
              configfile (hd1,1)/grub2/grub.cfg
            }
          '';
        };
      }
      {
        nix.maxJobs = 8;
        nix.buildCores = 8;
      
        services.xserver.synaptics = {
          enable = true;
          twoFingerScroll = true;
          vertEdgeScroll = true;
        };
      }
      {
        hardware.nvidiaOptimus.disable = true;
      }
      {
        services.logstash = {
          enable = true;
          inputConfig = ''
            file {
              path => "/home/rasen/log.txt.processed"
              sincedb_path => "/home/rasen/.log.txt.sincedb"
              codec => "json"
              start_position => "beginning"
              tags => [ "awesomewm" ]
              type => "awesomewm"
            }
            file {
              path => "/home/rasen/log.txt.ashmalko"
              sincedb_path => "/home/rasen/.log.txt.ashmalko.sincedb"
              codec => "json"
              start_position => "beginning"
              tags => [ "awesomewm" ]
              type => "awesomewm"
            }
            file {
              path => "/home/rasen/log.txt.omicron"
              sincedb_path => "/home/rasen/.log.txt.omicron.sincedb"
              codec => "json"
              start_position => "beginning"
              tags => [ "awesomewm" ]
              type => "awesomewm"
            }
          '';
          filterConfig = ''
            if [path] == "/home/rasen/log.txt.ashmalko" {
              mutate {
                replace => [ "host", "ashmalko" ]
              }
            }
            if [path] == "/home/rasen/log.txt.omicron" {
              mutate {
                replace => [ "host", "omicron" ]
              }
            }
          '';
          outputConfig = ''
            elasticsearch {
              index => "quantified-self"
              document_type => "awesomewm"
            }
          '';
        };
      
        services.elasticsearch = {
          enable = true;
          cluster_name = "ashmalko";
          extraConf = ''
            node.name: "${meta.name}"
          '';
        };
      
        services.kibana = {
          enable = true;
        };
      }
      {
        networking.localCommands = ''
          ip route del 10.2.0.0/22 via 10.7.0.52 2> /dev/null || true
          ip route add 10.2.0.0/22 via 10.7.0.52
        '';
      }
    ];
    ashmalko = [
      {
        nix.maxJobs = 4;
        nix.buildCores = 4;
      }
      {
        imports = [
          <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
        ];
      
        boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];
      
        boot.kernelParams = [ "intel_pstate=no_hwp" ];
        boot.loader.grub = {
          enable = true;
          version = 2;
          device = "/dev/sda";
          efiSupport = true;
        };
        boot.loader.efi.canTouchEfiVariables = true;
      }
      {
        boot.initrd.luks.devices = [
          {
            name = "root";
            device = "/dev/disk/by-uuid/a3eb801b-7771-4112-bb8d-42a9676e65de";
            preLVM = true;
            allowDiscards = true;
          }
        ];
      
        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/4184-7556";
          fsType = "vfat";
        };
      
        fileSystems."/" = {
          device = "/dev/disk/by-uuid/84d89f4b-7707-4580-8dbc-ec7e15e43b52";
          fsType = "ext4";
          options = [ "noatime" "nodiratime" "discard" ];
        };
      
        swapDevices = [
          { device = "/dev/disk/by-uuid/5a8086b0-627e-4775-ac07-b827ced6998b"; }
        ];
      }
      {
        services.gitolite = {
          enable = true;
          user = "git";
          adminPubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJhMhxIwZJgIY6CNSNEH+BetF/WCUtDFY2KTIl8LcvXNHZTh4ZMc5shTOS/ROT4aH8Awbm0NjMdW33J5tFMN8T7q89YZS8hbBjLEh8J04Y+kndjnllDXU6NnIr/AenMPIZxJZtSvWYx+f3oO6thvkZYcyzxvA5Vi6V1cGx6ni0Kizq/WV/mE/P1nNbwuN3C4lCtiBC9duvoNhp65PctQNohnKQs0vpQcqVlfqBsjQ7hhj2Fjg+Ofmt5NkL+NhKQNqfkYN5QyIAulucjmFAieKR4qQBABopl2F6f8D9IjY8yH46OCrgss4WTf+wxW4EBw/QEfNoKWkgVoZtxXP5pqAz rasen@Larry";
        };
      }
      {
        services.avahi.interfaces = [ "enp0s31f6" ];
      }
      {
        networking.firewall.allowedTCPPorts = [
          1883 8883 # Zink
          3000      # Grafana
        ];
      
        systemd.services.zink = {
          description = "Zink service";
          wantedBy = [ "multi-user.target" ];
          after = [ "grafana.service" ];
      
          serviceConfig =
            let zink =
              pkgs.rustPlatform.buildRustPackage {
                name = "zink-0.0.3";
      
                src = pkgs.fetchFromGitHub {
                  owner = "rasendubi";
                  repo = "zink";
                  rev = "influxdb-0.0.4";
                  sha256 = "0mnpss2is57y0ncdxwnal62w6yn4691b8lmka4fl3pyxhsblhww4";
                };
      
                cargoSha256 = "02v7nnsc0dbzd7kkfng0kgzwdlc85j1h7znzjpps7gcm3jz41lwz";
              };
            in {
              ExecStart = "${zink}/bin/zink timestamp,tagId,batteryLevel,temperature";
              Restart = "on-failure";
            };
        };
      
        services.influxdb.enable = true;
      
        services.grafana = {
          enable = true;
          addr = "0.0.0.0";
          port = 3000;
      
          domain = "ashmalko.local";
          auth.anonymous.enable = true;
        };
      }
      {
        networking.nat = {
          enable = true;
          internalInterfaces = [ "tap0" ];
          externalInterface = "enp0s31f6";
        };
      }
    ];
    omicron = [
      {
        imports = [
          <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
        ];
      
        boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];
      
        nix.maxJobs = lib.mkDefault 4;
      
        powerManagement.cpuFreqGovernor = "powersave";
      
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
      }
      {
        boot.initrd.luks.devices = [
          {
            name = "root";
            device = "/dev/disk/by-uuid/8b591c68-48cb-49f0-b4b5-2cdf14d583dc";
            preLVM = true;
          }
        ];
        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/BA72-5382";
          fsType = "vfat";
        };
        fileSystems."/" = {
          device = "/dev/disk/by-uuid/434a4977-ea2c-44c0-b363-e7cf6e947f00";
          fsType = "ext4";
          options = [ "noatime" "nodiratime" "discard" ];
        };
        fileSystems."/home" = {
          device = "/dev/disk/by-uuid/8bfa73e5-c2f1-424e-9f5c-efb97090caf9";
          fsType = "ext4";
          options = [ "noatime" "nodiratime" "discard" ];
        };
        swapDevices = [
          { device = "/dev/disk/by-uuid/26a19f99-4f3a-4bd5-b2ed-359bed344b1e"; }
        ];
      }
      {
        services.xserver.libinput = {
          enable = true;
          accelSpeed = "0.7";
        };
      }
      {
        i18n = {
          consolePackages = [
            pkgs.terminus_font
          ];
          consoleFont = "ter-132n";
        };
      }
      {
        boot.loader.grub.gfxmodeEfi = "1024x768";
      }
      {
        services.xserver.dpi = 276;
      }
    ];
  };

in
{
  imports = [
    {
      nixpkgs.config.allowUnfree = true;

      # The NixOS release to be compatible with for stateful data such as databases.
      system.stateVersion = "15.09";
    }

    {
      nix.nixPath =
        let dotfiles = "/home/rasen/dotfiles";
        in [
          "nixos-config=${dotfiles}/nixos/configuration.nix"
          "dotfiles=${dotfiles}"
          "${dotfiles}/channels"
        ];
    }
    {
      system.copySystemConfiguration = true;
    }
    {
      users.extraUsers.rasen = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "users" "wheel" "input" ];
        initialPassword = "HelloWorld";
      };
    }
    {
      nix.nixPath = [ "nixpkgs-overlays=/home/rasen/dotfiles/nixpkgs-overlays" ];
    }
    {
      nix.useSandbox = "relaxed";
    }
    {
      boot.kernelPackages = pkgs.linuxPackages_latest;
    }
    {
      networking = {
        hostName = meta.name;
    
        networkmanager.enable = true;
    
        # disable wpa_supplicant
        wireless.enable = false;
      };
    
      users.extraUsers.rasen.extraGroups = [ "networkmanager" ];
    
      environment.systemPackages = [
        pkgs.networkmanagerapplet
      ];
    }
    {
      hardware.pulseaudio = {
        enable = true;
        support32Bit = true;
      };
    
      environment.systemPackages = [ pkgs.pavucontrol ];
    }
    {
      services.locate = {
        enable = true;
        localuser = "rasen";
      };
    }
    {
      services.openvpn.servers = {
        kaa.config = ''
          client
          dev tap
          port 22
          proto tcp
          tls-client
          persist-key
          persist-tun
          ns-cert-type server
          remote vpn.kaa.org.ua
          ca /root/.vpn/ca.crt
          key /root/.vpn/alexey.shmalko.key
          cert /root/.vpn/alexey.shmalko.crt
        '';
      };
    }
    {
      services.avahi = {
        enable = true;
        browseDomains = [ ];
        interfaces = [ "tap0" ];
        nssmdns = true;
        publish = {
          enable = true;
          addresses = true;
        };
      };
    }
    {
      services.openssh = {
        enable = true;
        passwordAuthentication = false;
    
        # Disable default firewall rules
        ports = [];
        listenAddresses = [
          { addr = "0.0.0.0"; port = 22; }
        ];
      };
    
      # allow ssh from VPN network only
      networking.firewall = {
        extraCommands = ''
          ip46tables -D INPUT -i tap0 -p tcp -m tcp --dport 22 -j ACCEPT 2> /dev/null || true
          ip46tables -A INPUT -i tap0 -p tcp -m tcp --dport 22 -j ACCEPT
        '';
      };
    }
    {
      programs.mosh.enable = true;
    }
    {
      services.dnsmasq = {
        enable = true;
    
        # These are used in addition to resolv.conf
        servers = [
          "8.8.8.8"
          "8.8.4.4"
        ];
    
        extraConfig = ''
          listen-address=127.0.0.1
          cache-size=1000
    
          no-negcache
        '';
      };
    }
    {
      services.syncthing = {
        enable = true;
        user = "rasen";
        dataDir = "/home/rasen/.config/syncthing";
        openDefaultPorts = true;
      };
    }
    {
      networking.firewall = {
        enable = true;
        allowPing = false;
    
        connectionTrackingModules = [];
        autoLoadConntrackHelpers = false;
      };
    }
    {
      services.postgresql.enable = true;
      services.couchdb = {
        enable = true;
    
        package = pkgs.couchdb2;
    
        extraConfig = ''
          [httpd]
          enable_cors = true
    
          [cors]
          origins = *
          credentials = true
    
          [couch_peruser]
          enable = true
          delete_dbs = true
    
          [chttpd]
          authentication_handlers = {couch_httpd_auth, proxy_authentication_handler}, {couch_httpd_auth, cookie_authentication_handler}, {couch_httpd_auth, default_authentication_handler}
        '';
      };
    }
    {
      virtualisation.docker.enable = true;
    }
    {
      environment.systemPackages = [
        pkgs.isyncUnstable
      ];
    }
    {
      services.dovecot2 = {
        enable = true;
        enablePop3 = false;
        enableImap = true;
        mailLocation = "maildir:~/Mail:LAYOUT=fs";
      };
    
      # dovecot has some helpers in libexec (namely, imap).
      environment.pathsToLink = [ "/libexec/dovecot" ];
    }
    {
      environment.systemPackages = [
        pkgs.msmtp
      ];
    }
    {
      environment.systemPackages = [
        pkgs.notmuch
      ];
    }
    {
      services.xserver.enable = true;
    }
    {
      i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    }
    {
      time.timeZone = "Europe/Kiev";
    }
    {
      services.xserver.displayManager.slim.enable = true;
    }
    {
      services.xserver.displayManager.slim.enable = true;
      services.xserver.windowManager = {
        default = "awesome";
        awesome = {
          enable = true;
          luaModules = [ pkgs.luaPackages.luafilesystem pkgs.luaPackages.cjson ];
        };
      };
    }
    {
      services.xserver.desktopManager.xterm.enable = false;
    }
    {
      environment.systemPackages = [
        pkgs.wmname
        pkgs.xclip
        pkgs.escrotum
    
        # Control screen brightness
        pkgs.xorg.xbacklight
      ];
    }
    {
      services.xserver.layout = "us,ua";
      services.xserver.xkbVariant = "workman,";
    
      # Use same config for linux console
      i18n.consoleUseXkbConfig = true;
    }
    {
      services.xserver.xkbOptions = "grp:caps_toggle,grp:menu_toggle,grp_led:caps";
    }
    {
      services.redshift = {
        enable = true;
        latitude = "50.4500";
        longitude = "30.5233";
      };
    }
    {
      environment.systemPackages = [
        pkgs.oxygen-icons5
      ];
    }
    (let
      oldpkgs = import (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs-channels";
        rev = "1aa77d0519ae23a0dbef6cab6f15393cfadcc454";
        sha256 = "1gcd8938n3z0a095b0203fhxp6lddaw1ic1rl33q441m1w0i19jv";
      }) { config = config.nixpkgs.config; };
    in {
      environment.systemPackages = [ oldpkgs.oxygen-gtk2 oldpkgs.oxygen-gtk3 ];
    
      environment.shellInit = ''
        export GTK_PATH=$GTK_PATH:${oldpkgs.oxygen_gtk}/lib/gtk-2.0
        export GTK2_RC_FILES=$GTK2_RC_FILES:${oldpkgs.oxygen_gtk}/share/themes/oxygen-gtk/gtk-2.0/gtkrc
      '';
    })
    {
      environment.systemPackages = [
        pkgs.gnome3.adwaita-icon-theme
      ];
    }
    {
      fonts = {
        enableCoreFonts = true;
        enableFontDir = true;
        enableGhostscriptFonts = false;
    
        fonts = with pkgs; [
          inconsolata
          corefonts
          dejavu_fonts
          source-code-pro
          ubuntu_font_family
          unifont
        ];
      };
    }
    {
      environment.systemPackages = [
        pkgs.gwenview
        pkgs.dolphin
        pkgs.kde4.kfilemetadata
        pkgs.filelight
        pkgs.shared_mime_info
      ];
    }
    {
      environment.pathsToLink = [ "/share" ];
    }
    {
      environment.systemPackages = [
        pkgs.google-chrome
      ];
    }
    {
      environment.systemPackages = [
        pkgs.firefox-devedition-bin
      ];
    }
    (let
      oldpkgs = import (pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs-channels";
        rev = "14cbeaa892da1d2f058d186b2d64d8b49e53a6fb";
        sha256 = "0lfhkf9vxx2l478mvbmwm70zj3vfn9365yax7kvm7yp07b5gclbr";
      }) { config = config.nixpkgs.config; };
    in {
      nixpkgs.config.firefox = {
        icedtea = true;
      };
    
      environment.systemPackages = [
        (pkgs.runCommand "firefox-esr" { preferLocalBuild = true; } ''
          mkdir -p $out/bin
          ln -s ${oldpkgs.firefox-esr}/bin/firefox $out/bin/firefox-esr
        '')
      ];
    })
    {
      environment.systemPackages = [
        pkgs.zathura
      ];
    }
    {
      security.wrappers = {
        slock = {
          source = "${pkgs.slock}/bin/slock";
        };
      };
    }
    {
      environment.systemPackages = [
        pkgs.xss-lock
      ];
    }
    {
      environment.systemPackages = [
        pkgs.libreoffice
        pkgs.qbittorrent
        pkgs.deadbeef
    
        pkgs.vlc
        pkgs.mplayer
        pkgs.smplayer
    
        # pkgs.alarm-clock-applet
    
        # Used by naga setup
        pkgs.xdotool
    
        pkgs.hledger
        pkgs.drive
      ];
    }
    {
      environment.systemPackages = [
        (pkgs.vim_configurable.override { python3 = true; })
      ];
    }
    {
      environment.systemPackages = [
        pkgs.atom
      ];
    }
    {
      services.emacs = {
        enable = true;
        defaultEditor = true;
        package = (pkgs.emacsPackagesNgGen pkgs.emacs).emacsWithPackages (epkgs:
          [
            epkgs.orgPackages.org-plus-contrib
    
            epkgs.melpaStablePackages.use-package
    
            pkgs.ycmd
          ]
        );
      };
    }
    {
      environment.systemPackages = [
        pkgs.rxvt_unicode
      ];
    }
    {
      fonts = {
        fonts = [
          pkgs.powerline-fonts
          pkgs.terminus_font
        ];
      };
    }
    {
      programs.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
    }
    {
      environment.systemPackages = [
        pkgs.qrencode
        pkgs.feh
      ];
    }
    {
      programs.zsh.enable = true;
    }
    {
      environment.systemPackages = [
        pkgs.gitFull
        pkgs.gitg
      ];
    }
    {
      environment.systemPackages = [
        pkgs.tmux
      ];
    }
    {
      environment.systemPackages = [
        pkgs.minicom
        pkgs.openocd
        pkgs.telnet
        pkgs.saleae-logic
      ];
    }
    {
      users.extraGroups.plugdev = { };
      users.extraUsers.rasen.extraGroups = [ "plugdev" "dialout" ];
    
      services.udev.packages = [ pkgs.openocd pkgs.android-udev-rules ];
    }
    {
      environment.systemPackages = [
        pkgs.wget
        pkgs.htop
        pkgs.psmisc
        pkgs.zip
        pkgs.unzip
        pkgs.unrar
        pkgs.p7zip
        pkgs.irssi
        pkgs.bind
        pkgs.file
        pkgs.which
        pkgs.whois
        pkgs.utillinuxCurses
    
        pkgs.patchelf
    
        pkgs.nox
    
        pkgs.python
        pkgs.python3
      ];
    }
    {
      environment.systemPackages = [
        # pkgs.steam
      ];
    }
    {
      hardware.opengl.driSupport32Bit = true;
      hardware.pulseaudio.support32Bit = true;
    }
    {
      environment.systemPackages = [
        pkgs.nethack
      ];
    }
  ] ++ machine-config;
}
