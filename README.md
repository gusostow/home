My [Home Manager](https://nixos.wiki/wiki/Home_Manager) set up.

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
- Error on EC2
```
/home/ec2-user/.zshenv:.:2: no such file or directory: /Users/aostow/.nix-profile/etc/profile.d/hm-session-vars.sh
```
- Clipboard access on EC2
- Laptop home directory leaked into nvim config. Error from EC2:
```
Error detected while processing /home/ec2-user/.config/nvim/init.lua:
E5113: Error while calling lua chunk: /home/ec2-user/.config/nvim/init.lua:1: Vim(source):E484: Can't open file /Users/aostow/.config/nvim/init-home-manager.vim
stack traceback:
        [C]: in function 'cmd'
        /home/ec2-user/.config/nvim/init.lua:1: in main chunk
Press ENTER or type command to continue
```
- Distinguish hosts from the shell prompt. Instances config feels too similar to my laptop!
