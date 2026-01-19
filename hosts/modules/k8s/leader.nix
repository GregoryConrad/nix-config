{ config, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  # TODO on other server nodes:
  # services.k3s = {
  #   nodeIP = nodes.node2.networking.primaryIPAddress;
  #   serverAddr = "https://${nodes.node1.services.k3s.nodeIP}:6443";
  # };

  # TODO is there something like this for the k3s containerd?
  # https://rook.io/docs/rook/latest-release/Getting-Started/Prerequisites/prerequisites/?h=nix#nixos
  # systemd.services.containerd.serviceConfig = {
  # LimitNOFILE = lib.mkForce null;
  # };

  boot.kernelModules = [ "rbd" ]; # required for rook/ceph's rbd

  # NOTE: this enables us to use USB devices for rook/ceph, as they are ignored otherwise.
  # Switches all disk devices marked as "usb" to "scsi", which rook/ceph does not ignore.
  # Adapted from https://github.com/rook/rook/issues/14699#issuecomment-2350953135
  services.udev.extraRules = ''
    ACTION=="add", ENV{ID_TYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_BUS}="scsi"
    ACTION=="change", ENV{ID_TYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_BUS}="scsi"
    ACTION=="online", ENV{ID_TYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_BUS}="scsi"
  '';

  services.k3s = {
    enable = true;
    disable = [ "local-storage" ]; # NOTE: we are using Rook/Ceph instead

    # TODO fill in these fields for HA + multinode
    # extraFlags = [
    # NOTE: we need to use eth1 since we are in an integration test, where:
    # - eth0 is reserved for the NixOS test driver
    # - eth1 is reserved for inter-node communication
    # "--flannel-iface eth1"
    # ];
    # clusterInit = true;
    # token = "super-secret-token";
    # nodeIP = nodes.node1.networking.primaryIPAddress;

    autoDeployCharts =
      let
        immichTag = "v2.4.1";
        immichLibraryPvcName = "immich-library-pvc";
        # TODO use 18.1-1.0.0 below once immich supports it (probs in next release)
        immichPostgresImage = "ghcr.io/tensorchord/cloudnative-vectorchord:18.0-0.5.3";
      in
      {
        rook-ceph = {
          # https://rook.io/docs/rook/latest-release/Helm-Charts/operator-chart/
          name = "rook-ceph";
          repo = "https://charts.rook.io/release";
          version = "1.19.0";
          hash = "sha256-19gssKTaz95vpv1T1I6nCVgXqjniBgYNjRejM0QRxfI=";
          targetNamespace = "rook-ceph";
          createNamespace = true;
          values = {
            # https://rook.io/docs/rook/latest-release/Getting-Started/Prerequisites/prerequisites/?h=nix#nixos
            csi.csiRBDPluginVolume = [
              {
                name = "lib-modules";
                hostPath.path = "/run/booted-system/kernel-modules/lib/modules/";
              }
              {
                name = "host-nix";
                hostPath.path = "/nix";
              }
            ];
            csi.csiRBDPluginVolumeMount = [
              {
                name = "host-nix";
                mountPath = "/nix";
                readOnly = true;
              }
            ];
            csi.csiCephFSPluginVolume = [
              {
                name = "lib-modules";
                hostPath.path = "/run/booted-system/kernel-modules/lib/modules/";
              }
              {
                name = "host-nix";
                hostPath.path = "/nix";
              }
            ];
            csi.csiCephFSPluginVolumeMount = [
              {
                name = "host-nix";
                mountPath = "/nix";
                readOnly = true;
              }
            ];
          };
        };
        rook-ceph-cluster = {
          # https://rook.io/docs/rook/latest-release/Helm-Charts/ceph-cluster-chart/
          name = "rook-ceph-cluster";
          repo = "https://charts.rook.io/release";
          version = "1.19.0";
          hash = "sha256-/xExUHHiS9QeFxuZS+TJ1+SFHctC0Fl/YdTgSjaDYgs=";
          targetNamespace = "rook-ceph";
          createNamespace = true;
          values = {
            # https://github.com/rook/rook/blob/master/deploy/charts/rook-ceph-cluster/values.yaml
            cephClusterSpec = {
              dataDirHostPath = "/var/lib/rook";
              network.provider = "host";
              crashCollector.daysToRetain = 365;
              storage = {
                useAllNodes = false;
                useAllDevices = false;
                allowDeviceClassUpdate = true;
                allowOsdCrushWeightUpdate = true;
                nodes = [
                  {
                    name = "optimus";
                    devices = [
                      { name = "/dev/disk/by-id/usb-Seagate_Backup+_Mac_SL_NA5P7VX5-0:0"; }
                      { name = "/dev/disk/by-id/usb-SanDisk_Cruzer_Glide_4C530001280721116240-0:0"; }
                    ];
                  }
                  # TODO other devices, like rpi4?
                ];
              };

              # TODO remove all of these once we have multiple high-powered nodes
              mon.count = 1;
              mon.allowMultiplePerNode = true;
              mgr.allowMultiplePerNode = true;
              # mgr.modules = [ { name = "rook"; enabled = true; } ];
              resources.mon.limits.memory = "1Gi"; # default is 2Gi
              resources.osd.requests.memory = "2Gi"; # default is 4Gi
              resources.osd.limits.memory = "2Gi"; # default is 4Gi, but we have a very small cluster
            };

            # NOTE: we are disabling the default CephFilesystem + CephObjectStore
            # since we don't need them and they consume a ton of resources.
            # Consider re-enabling cephFileSystems if/when we get more powerful hardware
            # and wish to migrate immich over to CephFS.
            cephFileSystems = [ ];
            cephObjectStores = [ ];

            # TODO tailscale ingress?
            # https://rook.io/docs/rook/latest/Storage-Configuration/Monitoring/ceph-dashboard/
            # https://github.com/rook/rook/blob/561438d24171f94f217c8209608fcb0446f5a4de/deploy/charts/rook-ceph-cluster/values.yaml#L426
            ingress.dashboard = { };

            # TODO remove this (in order to use defaults) once we have multiple nodes
            cephBlockPools = [
              {
                name = "ceph-blockpool";
                spec = {
                  failureDomain = "host";
                  replicated = {
                    size = 1;
                  };
                };
                storageClass = {
                  enabled = true;
                  name = "ceph-block";
                  annotations = { };
                  labels = { };
                  isDefault = true;
                  reclaimPolicy = "Delete";
                  allowVolumeExpansion = true;
                  volumeBindingMode = "Immediate";
                  mountOptions = [ ];
                  allowedTopologies = [ ];
                  parameters = {
                    imageFormat = "2";
                    imageFeatures = "layering";
                    "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-rbd-provisioner";
                    "csi.storage.k8s.io/provisioner-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-rbd-provisioner";
                    "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/controller-publish-secret-name" = "rook-csi-rbd-provisioner";
                    "csi.storage.k8s.io/controller-publish-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-rbd-node";
                    "csi.storage.k8s.io/node-stage-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/fstype" = "ext4";
                  };
                };
              }
            ];
          };
        };
        cloudnative-pg = {
          # https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg
          name = "cloudnative-pg";
          repo = "https://cloudnative-pg.github.io/charts";
          version = "0.27.0";
          hash = "sha256-ObGgzQzGuWT4VvuMgZzFiI8U+YX/JM868lZpZnrFBGw=";
          targetNamespace = "cnpg-system";
          createNamespace = true;
        };
        immich-cnpg-cluster = {
          # https://github.com/cloudnative-pg/charts/tree/main/charts/cluster
          name = "cluster";
          repo = "https://cloudnative-pg.github.io/charts";
          version = "0.5.0";
          hash = "sha256-mldRwp6eLB12VdYCczujMyisTzAr4h+iSX0OYIKwcuA=";
          targetNamespace = "immich";
          createNamespace = true;
          values = {
            # https://github.com/cloudnative-pg/charts/blob/main/charts/cluster/values.yaml
            cluster.instances = 1;
            cluster.imageName = immichPostgresImage;
            cluster.storage.size = "8Gi";
            cluster.storage.storageClass = "ceph-block";
            cluster.postgresql.shared_preload_libraries = [ "vchord.so" ];
            cluster.initdb = {
              database = "immich";
              owner = "immich";
              postInitApplicationSQL = [ "ALTER USER immich WITH SUPERUSER;" ];
            };
          };
        };
        immich-deps = {
          package = pkgs.callPackage ./helm-chart.nix { chartDir = ./charts/immich-deps; };
          targetNamespace = "immich";
          createNamespace = true;
          values = {
            immich.library.pvc.name = immichLibraryPvcName;
          };
        };
        immich = {
          # https://github.com/immich-app/immich-charts
          name = "immich";
          repo = "https://immich-app.github.io/immich-charts";
          version = "0.10.3";
          hash = "sha256-E9lqIjUe1WVEV8IDrMAbBTJMKj8AzpigJ7fNDCYYo8Y=";
          targetNamespace = "immich";
          createNamespace = true;
          values = {
            # https://github.com/immich-app/immich-charts/blob/main/charts/immich/values.yaml
            immich.persistence.library.existingClaim = immichLibraryPvcName;
            valkey.enabled = true;
            controllers.main.containers.main = {
              image.tag = immichTag;
              env.DB_URL.valueFrom.secretKeyRef = {
                name = "immich-cnpg-cluster-app";
                key = "uri";
              };
            };
            # server.ingress.main.enabled = true; # TODO tailscale
          };
        };
        tailscale-operator = {
          # https://github.com/tailscale/tailscale/tree/main/cmd/k8s-operator/deploy
          name = "tailscale-operator";
          repo = "https://pkgs.tailscale.com/helmcharts";
          version = "1.92.5";
          hash = "sha256-nV0Ql9Z+Fcf7oH5SwmcNieIVBIoD37N+jNhGnzp+K8A=";
          targetNamespace = "tailscale";
          createNamespace = true;
        };
      };
  };

  # NOTE: make sure the node assigned to be the leader has access to this secret
  sops.secrets.tailscale-oauth = {
    sopsFile = ../../../secrets/tailscale-oauth.env;
    format = "dotenv";
  };

  systemd.services.tailscale-operator-secret = {
    description = "K8s Tailscale operator OAuth secret creation";
    after = [ "k3s.service" ];
    wants = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.k3s ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      until k3s kubectl cluster-info >/dev/null 2>&1; do
        sleep 1
      done

      source ${config.sops.secrets.tailscale-oauth.path}

      k3s kubectl -n tailscale create secret generic operator-oauth \
        --from-literal=client_id="$CLIENT_ID" \
        --from-literal=client_secret="$CLIENT_SECRET" \
        --dry-run=client -o yaml | k3s kubectl apply -f -
    '';
  };
}
