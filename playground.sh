#!/bin/bash

set -euo pipefail

message="$(cat)"

attrs=''
channel='stable'
code=''
mode='debug'

while :; do
	case "$message" in
		' '*)
			message="${message# }"
			;;

		'--beta'|'--beta '*)
			channel='beta'
			message="${message#--beta }"
			;;

		'--nightly'|'--nightly '*)
			channel='nightly'
			message="${message#--nightly }"
			;;

		'--release'|'--release '*)
			mode='release'
			message="${message#--release }"
			;;

		'#!['*)
			attr_end="$(expr index "$message" ']')"
			attrs="$(printf '%s%s\n' "$attrs" "${message:0:$attr_end}")"
			message="${message:$attr_end}"
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
		--arg attrs "$attrs" \
		--arg code "$code" \
		'{
			"code": (
				$attrs +
				"fn main() { println!(\"{:?}\", {\n\n" +
				$code +
				"\n\n}); }"
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
		--arg mode "$mode" \
		'$request_body_base + {
			"channel": $channel,
			"mode": $mode,
			"edition": "2018",
			"crateType": "bin",
			"tests": false,
			"backtrace": false
		}' |
		(
			curl \
				--max-time 10 \
				--silent \
				-X POST \
				-H 'user-agent: irc.freenode.net/Arnavion' \
				-H 'accept: application/json' \
				-H 'content-type: application/json' \
				--data-binary @- \
				'https://play.rust-lang.org/execute' ||
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
if [ "$irc_output" != "$output" ]; then
	create_gist=1
fi

if (( create_gist == 1 )); then
	printf '%s ...\n' "$irc_output"

	<<< "$request_body_base" curl \
		--max-time 10 \
		--silent \
		-H 'user-agent: irc.freenode.net/Arnavion' \
		-H 'accept: application/json' \
		-H 'content-type: application/json' \
		--data-binary @- \
		'https://play.rust-lang.org/meta/gist/' |
		jq -r '"https://play.rust-lang.org/?version=stable&mode=debug&edition=2018&gist=\(.id)"'
else
	printf '%s\n' "$irc_output"
fi

sleep 2
