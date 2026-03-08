# PRIV-IaaC

Repository containing IaaC used for my personal projects.

## Installing and pre-configuring `proxmox`

- flash with USB/balena,
- ZFS settings,
- Repository settings in proxmox,
- If using two NICs (like in t620), configure one as management NIC,
- Configure the other as service NIC.

## Setup and environment

This repository is meant to be used inside macOS environment.

### Tools

1. `asdf`,
2. `terraform`,
3. `packer`,
4. `1password`,
5. `editorconfig`,
6. `vscode`

### Using `asdf` as version manager for this project dependencies

This project utilizes usage of `.tool-versions` to manage versions of the dependencies.

Installation:

```sh
brew install asdf
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-~}/.zshrc
source ${ZDOTDIR:-~}/.zshrc
```

Then, you can use `asdf` to manage the versions, for example:

```sh
asdf plugin add terraform
asdf plugin add packer
asdf install
```

## License

This project is licensed under the GNU General Public License v3.0.
See [LICENSE](LICENSE).
