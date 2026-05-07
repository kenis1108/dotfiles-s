## Install Nix with Lix installer

[https://lix.systems/install/](https://lix.systems/install/)

## Install direnv

[https://github.com/direnv/direnv/blob/master/docs/installation.md](https://github.com/direnv/direnv/blob/master/docs/installation.md)

## Install nix-direnv

Put the following lines in your `~/.config/direnv/direnvrc`:

```bash
if ! has nix_direnv_version || ! nix_direnv_version 3.1.1; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.1.1/direnvrc" "sha256-p+fzQdrms/hDa7g+soShAybJNo4bN4SIAeSfqNKgD5I="
fi
```
