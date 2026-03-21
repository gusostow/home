Nix configuration for my personal devices.

- Home Manager for Macbook.
- NixOS + Home Manager for home server.

## Applying changes

On macbook, make changes to local checkout in `/Users/aostow/dev/home`. Then switch Home Manager
with:
```
$ nix-switch
```

On server, just run `nix-switch` to rebuild system and user Home Manager directly from the Github
flake on `main`.

`nix-switch` is zsh alias that is different depending on the host.

## Development

After cloning this repo, install pre-commit hooks to automatically format Nix files:

```bash
nix run .#install-hooks
```

## Secrets

0. Make sure `agenix` CLI is installed via `terminal.nix` Home module.
1. Register which public keys can decrypt secret in `./secrets/secrets.nix`
2. Create the encrypted secret interactively.
```sh
$ cd ./secrets
$ agenix -e foo.age
```
3. Use the secret by setting,
```nix
config.age.secrets.foo.file = ../../../secrets/foo.age
```
4. Reference the decrepyted path with,
```nix
config.age.secrets.foo.path
```

## New user setup

### Add internal CA to trust store

Mac

1. From my LAN, download root CA cert from http://ca.home/ca.cer.
2. Open it with Keychain and add it to the system trust store.

iphone

1. From my LAN, visit from http://ca.home/ca.cer.
2. You'll see a prompt "This website is trying to download a configuration profile"
3. Tap Allow
4. Install the profile:
  - Go to Settings → Profile Downloaded (appears at the top)
  - Hit install
5. Trust the certificate:
  - Go to Settings > General > About > Certificate Trust Settings
  - Toggle ON your CA certificate under "Enable Full Trust for Root Certificates"

### Create Keycloak account

1. Login with admin user in master realm `https://idp.home`.
2. Switch to `home` realm via Manage realms.
3. Users > Add user
    - Set Update Password as the only required user action
4. Set a temporary password: Users > $USER > Set password (temporary ON)

### Wireguard

Choose an IP for the new client on the `10.0.0.0/8` subnet. See used IPs in
[`wireguard.nix`](./nixos/modules/wireguard.nix).

On Ultan, run this to generate a wireguard config. It'll print the config which you need to paste
into a file to send to the user.

```
sudo generate-wireguard-client foo 10.0.0.6
```
It'll also give you instructions for updating `wireguard.nix` to add the newly generated public key.
