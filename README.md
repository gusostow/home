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
