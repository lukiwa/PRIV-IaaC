# PRIV-IaaC

## Using `asdf` as version manager for this project dependencies

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
