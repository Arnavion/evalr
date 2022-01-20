.PHONY: install

test:
	shellcheck -x *.sh

install:
	mkdir -p /etc/sysusers.d/
	cp --no-preserve=ownership evalr.sysusers /etc/sysusers.d/evalr.conf

	mkdir -p /usr/local/bin/
	cp --no-preserve=ownership evalr /usr/local/bin/evalr

	mkdir -p /usr/libexec/evalr/
	cp --no-preserve=ownership main.awk playground.sh /usr/libexec/evalr/

	mkdir -p /etc/evalr/
	chown evalr:evalr /etc/evalr
	chmod 0500 /etc/evalr

	mkdir -p /etc/systemd/system/
	cp --no-preserve=ownership evalr.service /etc/systemd/system/
	systemctl daemon-reload
