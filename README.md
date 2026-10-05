# chula-flake

NixOS modules for Chulalongkorn University.

```nix
inputs.chula = {
  url = "github:MiniHarinn/chula-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add `chula.nixosModules.default` to your host's modules.

## Wifi

NetworkManager profiles for ChulaWiFi and eduroam, logging in with your CUNET
account.

With [sops-nix](https://github.com/Mic92/sops-nix), add your credentials to your
sops file:

```yaml
chula:
  wifi:
    identity: your-cunet-username
    password: your-cunet-password
```

```nix
chula.wifi = {
  enable = true;
  sops.enable = true;
};
```

Without sops-nix, point `chula.wifi.environmentFile` at a root-owned file
outside the Nix store:

```sh
CHULA_WIFI_IDENTITY=your-cunet-username
CHULA_WIFI_PASSWORD=your-cunet-password
```

## Development

```sh
nix fmt
nix flake check ./dev
```
