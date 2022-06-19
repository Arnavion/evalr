BEGIN {
	write_line("NICK " IRC_NICKNAME)
	write_line("USER " IRC_USERNAME " 0 * :Bot owned by Arnavion")
	if (IRC_PASSWORD != "") {
		write_line("PRIVMSG nickserv :IDENTIFY " IRC_USERNAME " " IRC_PASSWORD)
	}

	channel_privmsg_regex = "^:?" IRC_NICKNAME ":"
	highlight_regex = "^" IRC_NICKNAME ":"
}

{
	sub(/\r$/, "")
	read_line()
	command = "/usr/bin/touch " XDG_RUNTIME_DIR "/last-event"
	print "" |& command
	while ((command |& getline) > 0) { }
	close(command)
}

/^PING$/ {
	write_line("PONG")
}

/^PING / {
	write_line("PONG " $2)
}

/^[^ ]+ 001 / {
	if (IRC_PASSWORD == "") {
		write_line("JOIN " IRC_CHANNEL)
	}
}

/^:NickServ!NickServ@services\.[^ ]* NOTICE / {
	if ($3 == IRC_NICKNAME) {
		message = get_variadic(4)

		if (message ~ /^You are now identified for /) {
			write_line("JOIN " IRC_CHANNEL)
		}
	}
}

$0 ~ "^[^ ]+ PRIVMSG " IRC_CHANNEL " " {
	if ($4 ~ channel_privmsg_regex) {
		printf "=== Acting on request\n" > "/dev/stderr"

		split(substr($1, 2), nick_parts, "!")
		nick = nick_parts[1]

		message = get_variadic(4)
		sub(highlight_regex, "", message)

		command = "/usr/libexec/evalr/playground.sh"
		printf "%s", message |& command
		fflush()
		close(command, "to")
		while ((command |& getline) > 0) {
			write_line("NOTICE " IRC_CHANNEL " :" nick ": " $0)
		}
		close(command)
	}
}

/^[^ ]+ PRIVMSG / {
	if ($3 == IRC_NICKNAME) {
		split(substr($1, 2), nick_parts, "!")
		nick = nick_parts[1]

		message = get_variadic(4)

		if (substr(message, 1, 1) != "\x01") {
			printf "=== Acting on request\n" > "/dev/stderr"

			sub(highlight_regex, "", message)

			command = "/usr/libexec/evalr/playground.sh"
			printf "%s", message |& command
			fflush()
			close(command, "to")
			while ((command |& getline) > 0) {
				write_line("PRIVMSG " nick " :" $0)
			}
			close(command)
		}
	}
}

function read_line() {
	printf "<<< %s\n", $0 > "/dev/stderr"
}

function write_line(line) {
	printf ">>> %s\n", line > "/dev/stderr"
	printf "%s\r\n", line
	fflush()
}

function get_variadic(i) {
	first = $i
	if (sub(/^:/, "", first) == 0) {
		return first
	}

	start_at = 0
	for (j = 1; j < i; j++) {
		start_at += length($j) + length(" ")
	}
	start_at += length(":")
	return substr($0, start_at + 1)
}
