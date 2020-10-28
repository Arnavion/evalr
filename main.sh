#!/bin/bash

set -euo pipefail

. creds

rm -f server
trap 'rm -f server' EXIT
mkfifo server

# server is a fifo
#
# shellcheck disable=SC2094
<server awk \
	-f main.awk \
	-v "IRC_NICKNAME=$IRC_NICKNAME" \
	-v "IRC_USERNAME=$IRC_USERNAME" \
	-v "IRC_PASSWORD=${IRC_PASSWORD:-}" |
	openssl s_client -connect "$IRC_SERVER" -quiet >server
