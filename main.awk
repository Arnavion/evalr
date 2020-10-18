BEGIN {
	write_line(sprintf("NICK %s", IRC_NICKNAME))
	write_line(sprintf("USER %s 0 * :Bot owned by Arnavion", IRC_USERNAME))
	if (IRC_PASSWORD != "") {
		write_line(sprintf("PRIVMSG nickserv :IDENTIFY %s %s", IRC_USERNAME, IRC_PASSWORD))
	}

	channel_privmsg_regex = sprintf("^:?%s:", IRC_NICKNAME)
	privmsg_regex = sprintf("^:?%s:", IRC_NICKNAME)
	highlight_regex = sprintf("^%s:", IRC_NICKNAME)
}

{
	gsub(/\r$/, "")
	read_line()
}

/^PING\r$/ {
	write_line("PONG")
}

/^PING / {
	write_line(sprintf("PONG %s", $2))
}

/^[^ ]+ 001 / {
	if (IRC_PASSWORD == "") {
		write_line("JOIN ##rust")
	}
}

/^:NickServ!NickServ@services\. NOTICE / {
	if ($3 == IRC_NICKNAME) {
		message = ""
		for (i = 4; i <= NF; i++) {
			message = sprintf("%s%s ", message, $i)
		}
		gsub(/^:/, "", message)

		if (message ~ /^You are now identified for /) {
			write_line("JOIN ##rust")
		}
	}
}

/^[^ ]+ PRIVMSG ##rust / {
	if ($4 ~ channel_privmsg_regex) {
		printf "=== Acting on request\n" > "/dev/stderr"

		split(substr($1, 2), nick_parts, "!")
		nick = nick_parts[1]

		message = ""
		for (i = 4; i <= NF; i++) {
			message = sprintf("%s%s ", message, $i)
		}
		gsub(channel_privmsg_regex, "", message)

		command = "./playground.sh"
		printf "%s", message |& command
		fflush()
		close(command, "to")
		while ((command |& getline) > 0) {
			write_line(sprintf("NOTICE ##rust :%s: %s", nick, $0))
		}
		close(command)
	}
}

/^[^ ]+ PRIVMSG / {
	if ($3 == IRC_NICKNAME) {
		split(substr($1, 2), nick_parts, "!")
		nick = nick_parts[1]

		message = ""
		for (i = 4; i <= NF; i++) {
			message = sprintf("%s%s ", message, $i)
		}
		gsub(/^:/, "", message)

		if (substr(message, 1, 1) != "\x01") {
			printf "=== Acting on request\n" > "/dev/stderr"

			gsub(highlight_regex, "", message)

			command = "./playground.sh"
			printf "%s", message |& command
			fflush()
			close(command, "to")
			while ((command |& getline) > 0) {
				write_line(sprintf("PRIVMSG %s :%s", nick, $0))
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
