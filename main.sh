#!/bin/bash

set -euo pipefail

. creds

coproc GAWK {
	gawk \
		-f main.awk \
		-v "IRC_NICKNAME=$IRC_NICKNAME" \
		-v "IRC_USERNAME=$IRC_USERNAME" \
		-v "IRC_PASSWORD=${IRC_PASSWORD:-}"
}

<&"${GAWK[0]}" openssl s_client -connect "$IRC_SERVER" -quiet >&"${GAWK[1]}"
