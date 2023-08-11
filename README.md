This is an IRC bot that evaluates code snippets using <https://play.rust-lang.org> and prints the results.


# Dependencies

Required:

- `gawk`
- `jq`
- `openssl`

Optional:

- `make` - if you use the Makefile to install the services files


# Install

```sh
# Install binaries and systemd service.
sudo make install

# Create creds file. "IRC_PASSWORD" is optional.
cat <<-EOF | sudo tee /etc/evalr/creds >/dev/null
IRC_SERVER=...
IRC_NICKNAME=...
IRC_USERNAME=...
IRC_PASSWORD=...
IRC_CHANNEL=...
EOF
sudo chmod 0600 /etc/evalr/creds

sudo systemctl enable --now evalr
```


# License

AGPL-3.0-only

```
evalr

https://github.com/Arnavion/evalr

Copyright 2020 Arnav Singh

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, version 3 of the
License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
