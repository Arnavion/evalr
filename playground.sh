#!/bin/bash

set -euo pipefail

PLAYGROUND_BASE_URI='https://play.rust-lang.org/'
# PLAYGROUND_BASE_URI='https://play.integer32.com/'

message="$(cat)"

attrs=()
channel='stable'
code=''
edition='2021'
mode='debug'

while :; do
	case "$message" in
		' '*)
			message="${message# }"
			;;

		'--beta'|'--beta '*)
			channel='beta'
			message="${message#--beta}"
			;;

		'--2015'|'--2015 '*)
			edition='2015'
			message="${message#--2015}"
			;;

		'--2018'|'--2018 '*)
			edition='2018'
			message="${message#--2018}"
			;;

		'--2021'|'--2021 '*)
			edition='2021'
			message="${message#--2021}"
			;;

		'--2024'|'--2024 '*)
			edition='2024'
			message="${message#--2024}"
			;;

		'--nightly'|'--nightly '*)
			channel='nightly'
			message="${message#--nightly}"
			;;

		'--release'|'--release '*)
			mode='release'
			message="${message#--release}"
			;;

		'#!['*)
			attrs+=("${message%%]*}]")
			message="${message#*]}"
			;;

		*)
			code="$message"
			break
			;;
	esac
done

if [ -z "$code" ]; then
	exit 0
fi

request_body_base="$(
	jq -cn \
		--arg attrs "$(for attr in "${attrs[@]}"; do printf '%s\n' "$attr"; done)" \
		--arg code "$code" \
		'{
			"code": (
				$attrs +
				(if ($attrs | length) > 0 then "\n" else "" end) +
				"fn main() { println!(\"{:?}\", {\n\n" +
				$code +
				"\n\n}); }\n"
			)
		}'
)"

if [ -n "${EVALR_TEST:-}" ]; then
	jq -cn \
		--argjson request_body_base "$request_body_base" \
		--arg channel "$channel" \
		--arg mode "$mode" \
		'$request_body_base + {
			"channel": $channel,
			"mode": $mode
		}'
	exit 0
fi

response="$(
	jq -cn \
		--argjson request_body_base "$request_body_base" \
		--arg channel "$channel" \
		--arg edition "$edition" \
		--arg mode "$mode" \
		'$request_body_base + {
			"channel": $channel,
			"mode": $mode,
			"edition": $edition,
			"crateType": "bin",
			"tests": false,
			"backtrace": false
		}' |
		(
			curl \
				--location \
				--max-time 10 \
				--silent \
				-X POST \
				-H 'user-agent: irc.libera.chat/Arnavion' \
				-H 'accept: application/json' \
				-H 'content-type: application/json' \
				--data-binary @- \
				"${PLAYGROUND_BASE_URI}execute" ||
			:
		)
)"

create_gist=0
if [ -n "$response" ] && (<<< "$response" jq -er '.success' >/dev/null); then
	output="$(<<< "$response" jq -r '.stdout')"
else
	output="$(
		(
			<<< "$response" jq -r '.stderr' |
			grep -E "^(error|thread 'main' panicked at)"
		) ||
		printf 'unknown error'
	)"
	create_gist=1
fi

irc_output="$(<<< "$output" head -n 1 | head -c 64)"
if [ "$irc_output" != "$output" ] && [ "$(printf '%s\n()' "$irc_output")" != "$output" ]; then
	create_gist=1
fi

if (( create_gist == 1 )); then
	printf '%s ...\n' "$irc_output"

	<<< "$request_body_base" curl \
		--location \
		--max-time 10 \
		--silent \
		-H 'user-agent: irc.libera.chat/Arnavion' \
		-H 'accept: application/json' \
		-H 'content-type: application/json' \
		--data-binary @- \
		"${PLAYGROUND_BASE_URI}meta/gist" |
		jq -r \
			--arg playground_base_uri "$PLAYGROUND_BASE_URI" \
			--arg channel "$channel" \
			--arg edition "$edition" \
			--arg mode "$mode" \
			'"\($playground_base_uri)?version=\($channel)&mode=\($mode)&edition=\($edition)&gist=\(.id)"'
else
	printf '%s\n' "$irc_output"
fi

sleep 2
