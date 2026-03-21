# PRIV-IaaC

> [!WARNING]
Documentation in this project is still under development and serves more like "notes to self".
Some documentation parts were written by Copilot thus may be a bit misleading or not to the point :)

> [!WARNING]
Some parts of the project are tied to my Homelab environment (server names and hardware, 1Password paths, OPNsense configuration, HDD ids, etc.),

Infrastructure as Code repository for personal environments.

## Installing and pre-configuring `proxmox`

- flash with USB/balena,
- ZFS settings,
- Repository settings in proxmox,
- If using two NICs (like in t620), configure one as management NIC,
- Configure the other as service NIC.

## Setup and environment

This repository is intended for macOS.

Required tools:

- `asdf`
- `terraform`
- `packer`
- `1password`
- `editorconfig`
- `vscode`

## Tool version management (`asdf`)

Tool versions are defined in `.tool-versions`.

Install `asdf`:

```sh
brew install asdf
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-~}/.zshrc
source ${ZDOTDIR:-~}/.zshrc
```

Install plugins and configured versions:

```sh
asdf plugin add terraform
asdf plugin add packer
asdf install
```

## License

This project is licensed under the GNU General Public License v3.0.
See [LICENSE](LICENSE).
