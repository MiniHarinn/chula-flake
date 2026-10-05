{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.chula.wifi;

  mkProfile = ssid: identity: priority: {
    connection = {
      id = ssid;
      type = "wifi";
      autoconnect-priority = toString priority;
    };
    wifi.ssid = ssid;
    wifi-security.key-mgmt = "wpa-eap";
    "802-1x" = {
      eap = "peap";
      phase2-auth = "mschapv2";
      inherit identity;
      password = "$CHULA_WIFI_PASSWORD";
      # Chula's RADIUS only speaks TLS 1.0/1.1.
      openssl-ciphers = "DEFAULT@SECLEVEL=0";
      ca-cert = "${./radius-ca.pem}";
      domain-suffix-match = "chula.ac.th";
    };
  };
in
{
  options.chula.wifi = {
    enable = lib.mkEnableOption "ChulaWiFi and eduroam";

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.externalPath;
      default = null;
      description = "File setting `CHULA_WIFI_IDENTITY` and `CHULA_WIFI_PASSWORD`.";
    };

    sops.enable = lib.mkEnableOption "reading the credentials from sops-nix";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.environmentFile != null;
            message = "chula.wifi needs environmentFile, or sops.enable with sops-nix imported.";
          }
        ];

        networking.networkmanager.ensureProfiles = {
          environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
          profiles = {
            chula-wifi = mkProfile "ChulaWiFi" "$CHULA_WIFI_IDENTITY" 10;
            chula-eduroam = mkProfile "eduroam" "$CHULA_WIFI_IDENTITY@eduroam.chula.ac.th" 0;
          };
        };
      }

      # Only define sops options when sops-nix is imported.
      (lib.optionalAttrs (options ? sops) (
        lib.mkIf cfg.sops.enable {
          sops.secrets."chula-wifi/identity".key = lib.mkDefault "chula/wifi/identity";
          sops.secrets."chula-wifi/password".key = lib.mkDefault "chula/wifi/password";
          sops.templates."chula-wifi.env" = {
            content = ''
              CHULA_WIFI_IDENTITY=${config.sops.placeholder."chula-wifi/identity"}
              CHULA_WIFI_PASSWORD=${config.sops.placeholder."chula-wifi/password"}
            '';
            restartUnits = [ "NetworkManager-ensure-profiles.service" ];
          };
          chula.wifi.environmentFile = lib.mkDefault config.sops.templates."chula-wifi.env".path;
        }
      ))
    ]
  );
}
