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
# Install binaries and systemd service, and create service user.
sudo make install

# Create creds file. "IRC_PASSWORD" is optional.
cat <<-EOF | sudo tee /var/lib/evalr/creds >/dev/null
IRC_SERVER=...
IRC_NICKNAME=...
IRC_USERNAME=...
IRC_PASSWORD=...
EOF
sudo chown evalr:evalr /var/lib/evalr/creds
sudo chmod 0600 /var/lib/evalr/creds

systemctl enable --now evalr
```


# License

```
evalr

https://github.com/Arnavion/evalr

Copyright 2020 Arnav Singh

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
