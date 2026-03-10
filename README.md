# PRIV-IaaC

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

## Proxmox

Packer and Proxmox build configuration is located in [packer/](packer/).

## License

This project is licensed under the GNU General Public License v3.0.
See [LICENSE](LICENSE).
