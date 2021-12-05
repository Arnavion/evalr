.PHONY: install

test:
	shellcheck -x *.sh

install:
	if ! /bin/getent group evalr >/dev/null; then \
		/sbin/groupadd --system evalr; \
	fi

	if ! /bin/getent passwd evalr >/dev/null; then \
		/sbin/useradd --system --gid evalr --comment 'evalr user' --shell /sbin/nologin --no-create-home evalr; \
	fi

	mkdir -p /usr/local/bin/
	cp --no-preserve=ownership evalr /usr/local/bin/evalr

	mkdir -p /usr/libexec/evalr/
	cp main.awk playground.sh /usr/libexec/evalr/
	chown -R evalr:evalr /usr/libexec/evalr/

	mkdir -p /etc/evalr/

	mkdir -p /etc/systemd/system/
	cp evalr.service /etc/systemd/system/
	chown root:root /etc/systemd/system/evalr.service
	systemctl daemon-reload
