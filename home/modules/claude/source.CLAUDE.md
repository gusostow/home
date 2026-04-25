# Layout

Skills are defined in the home Nix repo, typically at `~/dev/home`. They're symlinked into `~/.claude/skills`.

# Tips

## Installing missing software

Use `uv run --with` any time a dependency that is available is missing that's available on pypi. Do
not try to globally install the package with pip.

```
uv run --with 'pandoc' -- pandoc --help
```

Use one-off `nix run` commands to install missing non-pypi packages.

```
nix run nixpkgs#gcc -- --help
```

# Reminders

`~/dev/home` is not my home directory. It's my Nix Home Manager config repo.

# Style

Comments should be in this style:
- If a single sentence
  - Start lowercase unless proper noun.
  - Don't end in a period.
- elif >1 sentence
  - Start with an upper-case. 
  - End all sentences with periods.
