{ disko, ... }:
{
  imports = [ disko.nixosModules.disko ];

  services.btrfs.autoScrub.enable = true;

  # https://github.com/nix-community/disko/blob/master/docs/disko-images.md
  disko.devices = {
    disk.main = {
      device = "/dev/disk/by-id/TODO_THE_SATA_SSD";
      type = "disk";
      imageSize = "8G"; # WARN: must be big enough to contain full OS
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
