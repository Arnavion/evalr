.PHONY: install

test:
	shellcheck -x *.sh

install:
	mkdir -p /usr/local/bin/
	cp --no-preserve=ownership evalr /usr/local/bin/evalr

	mkdir -p /usr/libexec/evalr/
	cp --no-preserve=ownership main.awk playground.sh /usr/libexec/evalr/

	mkdir -p /etc/evalr/
	chmod 0700 /etc/evalr

	mkdir -p /etc/systemd/system/
	cp --no-preserve=ownership evalr.service /etc/systemd/system/
	systemctl daemon-reload
