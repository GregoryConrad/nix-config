{
  # Adapted from: https://github.com/nvmd/nixos-raspberrypi-demo/blob/main/pi5-configtxt.nix
  hardware.raspberry-pi.config.pi5.base-dt-params = {
    # https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#enable-pcie
    pciex1 = {
      enable = true;
      value = "on";
    };

    # https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#pcie-gen-3-0
    pciex1_gen = {
      enable = true;
      value = "3";
    };
  };
}
