# Without radios the profiles never activate, so this checks what NetworkManager
# loads: credentials substituted, CA pinned, both profiles present.
{
  pkgs,
  chula,
  sops-nix,
}:
let
  base = {
    imports = [ chula.nixosModules.default ];
    networking.networkmanager.enable = true;
    chula.wifi.enable = true;
  };

  testScript = ''
    # A oneshot that exits, so wait on its effect rather than the unit.
    machine.wait_for_unit("NetworkManager.service")
    machine.wait_until_succeeds("nmcli -g NAME connection show | grep -x ChulaWiFi")
    machine.wait_until_succeeds("nmcli -g NAME connection show | grep -x eduroam")
    machine.succeed("systemctl show -P Result NetworkManager-ensure-profiles.service | grep -x success")

    def setting(name, field):
        return machine.succeed(f"nmcli -s -g {field} connection show {name}").strip()

    assert setting("ChulaWiFi", "802-1x.identity") == "testuser"
    assert setting("eduroam", "802-1x.identity") == "testuser@eduroam.chula.ac.th"
    for name in ["ChulaWiFi", "eduroam"]:
        assert setting(name, "802-1x.password") == "p@ss $word", name
        assert setting(name, "802-1x.ca-cert").endswith("-radius-ca.pem"), name
  '';
in
{
  wifi = pkgs.testers.runNixOSTest {
    name = "chula-wifi";
    nodes.machine = {
      imports = [ base ];
      chula.wifi.environmentFile = "/etc/chula-wifi.env";
      environment.etc."chula-wifi.env".text = ''
        CHULA_WIFI_IDENTITY=testuser
        CHULA_WIFI_PASSWORD='p@ss $word'
      '';
    };
    inherit testScript;
  };

  wifi-sops = pkgs.testers.runNixOSTest {
    name = "chula-wifi-sops";
    nodes.machine = {
      imports = [
        base
        sops-nix.nixosModules.sops
      ];
      chula.wifi.sops.enable = true;
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = "/run/age-key.txt";
        age.sshKeyPaths = [ ];
        gnupg.sshKeyPaths = [ ];
      };
      # Test-only key, committed on purpose: it guards nothing but the fixture.
      # sops-nix refuses a key in the store, so install it before decryption.
      system.activationScripts.chulaTestAgeKey.text = ''
        install -m 0400 ${./age-key.txt} /run/age-key.txt
      '';
      system.activationScripts.setupSecrets.deps = [ "chulaTestAgeKey" ];
    };
    inherit testScript;
  };
}
