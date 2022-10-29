My [Nix Home Manager](https://nixos.wiki/wiki/Home_Manager) set up.

# Set up

Get this repo.
```
$ curl -L https://github.com/gusostow/home/tarball/main -o main.tar.gz
$ tar xvf main.tar.gz
$ mv gusostow-home-* home  # rename output of tarball
```
Run the bootstrap set up script. It installs Nix, Home Manager, and symlinks the config from the repo into place.
```
$ ./home/bootstrap.sh
```

# TODO/FIXME

- Set zsh as default shell
- Clipboard access on EC2
- Distinguish hosts from the shell prompt. Instances config feels too similar to my laptop!
