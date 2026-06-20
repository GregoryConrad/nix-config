# NOTE: only one node in the cluster should be given this module.
# See: https://docs.k3s.io/installation/packaged-components#user-addons
{ config, pkgs, ... }:
let
  immichTag = "v2.7.5";
  immichPostgresImage = "ghcr.io/tensorchord/cloudnative-vectorchord:18.3-1.1.1";
  immichLibraryPvcName = "immich-library-pvc"; # WARN: DO NOT CHANGE!!
  immichLibraryPvcSize = "100Gi"; # WARN: increase only; do not decrease!
  immichPostgresDbSize = "4Gi"; # WARN: increase only; do not decrease!
in
{
  services.k3s = {
    autoDeployCharts = {
      rook-ceph = {
        # https://rook.io/docs/rook/latest-release/Helm-Charts/operator-chart/
        name = "rook-ceph";
        repo = "https://charts.rook.io/release";
        version = "1.20.1";
        hash = "sha256-65fg+IPaLaMXo/4i5sWFpS1otfgh0M6aiL0F+10lXrs=";
        targetNamespace = "rook-ceph";
        createNamespace = true;
        values = {
          # https://github.com/rook/rook/blob/master/deploy/charts/rook-ceph/values.yaml
          enableDiscoveryDaemon = true; # for "Physical Disks" in Ceph dashboard
          csi.enableCephfsDriver = false; # NOTE: not using CephFS right now; save on some resources

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
        version = "1.20.1";
        hash = "sha256-08mCsMPhDegk9cHsTiiL0AQAlD4+HbezgjuMDf5tJzM=";
        targetNamespace = "rook-ceph";
        createNamespace = true;
        values = {
          # https://github.com/rook/rook/blob/master/deploy/charts/rook-ceph-cluster/values.yaml
          toolbox.enabled = true;
          cephClusterSpec = {
            dataDirHostPath = "/var/lib/rook";
            network.provider = "host";
            crashCollector.daysToRetain = 365;
            dashboard.ssl = false; # using Tailscale Ingress, which handles SSL for us

            mgr.modules = [
              # Required for "Physical Disks" in Ceph dashboard
              {
                name = "rook";
                enabled = true;
              }
            ];

            storage = {
              useAllNodes = false;
              useAllDevices = false;
              allowDeviceClassUpdate = true;
              allowOsdCrushWeightUpdate = true;
              nodes = [
                {
                  name = "optimus";
                  devices = [
                    { name = "/dev/disk/by-id/ata-WDC_WD10EZEX-75ZF5A0_WD-WMC1S5660016"; }
                  ];
                }
                {
                  name = "rpi5";
                  devices = [
                    { name = "/dev/disk/by-id/nvme-CT2000P310SSD8_254554493560"; }
                  ];
                }
                {
                  name = "octopi";
                  devices = [
                    { name = "/dev/disk/by-id/usb-Seagate_Backup+_Mac_SL_NA5P7VX5-0:0"; }
                  ];
                }
              ];
            };

            # NOTE: the default CPU requests for these are a little high.
            # Given we are dealing with some raspberry pis, which only have 4 cores,
            # disable the CPU requests entirely.
            resources.mgr.requests.cpu = null;
            resources.mon.requests.cpu = null;
            resources.osd.requests.cpu = null;
            resources.cleanup.requests.cpu = null;
          };

          # NOTE: we are disabling the default CephFilesystem + CephObjectStore
          # since we don't need them and they consume a ton of resources.
          # Consider re-enabling cephFileSystems if/when we get more powerful hardware
          # and wish to migrate immich over to CephFS.
          cephFileSystems = [ ];
          cephObjectStores = [ ];

          # https://rook.io/docs/rook/latest/Storage-Configuration/Monitoring/ceph-dashboard/
          ingress.dashboard = {
            ingressClassName = "tailscale";
            host.name = "ceph-dashboard";
            tls = [ { hosts = [ "ceph-dashboard" ]; } ];
          };
        };
      };
      headlamp = {
        # https://github.com/kubernetes-sigs/headlamp/tree/main/charts/headlamp
        name = "headlamp";
        repo = "https://kubernetes-sigs.github.io/headlamp";
        version = "0.43.0";
        hash = "sha256-amuBAphMB98x2ADCfg6o/JHHZjZrp/zcL/QROwOumnU=";
        targetNamespace = "kube-system";
        createNamespace = true;
        values = {
          ingress = {
            enabled = true;
            ingressClassName = "tailscale";
            tls = [ { hosts = [ "headlamp" ]; } ];
            hosts = [
              {
                host = "headlamp";
                paths = [
                  {
                    path = "/";
                    type = "Prefix";
                  }
                ];
              }
            ];
          };
        };
      };
      cloudnative-pg = {
        # https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg
        name = "cloudnative-pg";
        repo = "https://cloudnative-pg.github.io/charts";
        version = "0.28.3";
        hash = "sha256-oiDxdLcmN/UFVTucD92wuf7QM4DVi+Fxk1zZnYgId9Y=";
        targetNamespace = "cnpg-system";
        createNamespace = true;
      };
      immich-cnpg-cluster = {
        # https://github.com/cloudnative-pg/charts/tree/main/charts/cluster
        name = "cluster";
        repo = "https://cloudnative-pg.github.io/charts";
        version = "0.7.0";
        hash = "sha256-AEl53dz134xeNYn6bMV05MTkxr/6wSOFSZCM8hucK18=";
        targetNamespace = "immich";
        createNamespace = true;
        values = {
          # https://github.com/cloudnative-pg/charts/blob/main/charts/cluster/values.yaml
          cluster.instances = 3;
          cluster.imageName = immichPostgresImage;
          cluster.storage.size = immichPostgresDbSize;
          cluster.storage.storageClass = "ceph-block";
          cluster.postgresql.shared_preload_libraries = [ "vchord.so" ];
          cluster.initdb = {
            database = "immich";
            owner = "immich";
            postInitApplicationSQL = [ "ALTER USER immich WITH SUPERUSER;" ];
          };
        };
      };
      immich = {
        # https://github.com/immich-app/immich-charts
        name = "immich";
        repo = "https://immich-app.github.io/immich-charts";
        version = "0.12.0";
        hash = "sha256-ci+4BJs5VBLy8hVaYD2Ear2hD5Y9WgYYUUFhoYDaEUg=";
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
          server.ingress.main = {
            enabled = true;
            className = "tailscale";
            tls = [ { hosts = [ "immich" ]; } ];
            hosts = [
              {
                host = "immich";
                paths = [ { path = "/"; } ];
              }
            ];
          };
        };
      };
      tailscale-operator = {
        # https://github.com/tailscale/tailscale/tree/main/cmd/k8s-operator/deploy
        name = "tailscale-operator";
        repo = "https://pkgs.tailscale.com/helmcharts";
        version = "1.98.3";
        hash = "sha256-p0E+sM6RWB/2b8caF9oM8Zoagi7XqE+0tSeGzrFwZaA=";
        targetNamespace = "tailscale";
        createNamespace = true;
      };
    };

    manifests.immich-pvc.content = {
      apiVersion = "v1";
      kind = "PersistentVolumeClaim";
      metadata = {
        name = immichLibraryPvcName;
        namespace = "immich";
      };
      spec = {
        storageClassName = "ceph-block";
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = immichLibraryPvcSize;
      };
    };
  };

  # WARN: make sure the node assigned to be the leader has access to this secret!
  sops.secrets.tailscale-oauth = {
    sopsFile = ../../secrets/tailscale-oauth.env;
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

      until k3s kubectl describe namespace tailscale >/dev/null 2>&1; do
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
