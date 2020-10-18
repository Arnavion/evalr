.PHONY: install

install:
	if ! /bin/getent group evalr >/dev/null; then \
		/sbin/groupadd --system evalr; \
	fi

	if ! /bin/getent passwd evalr >/dev/null; then \
		/sbin/useradd --system --gid evalr --commend 'evalr user' --shell /sbin/nologin --home-dir /var/lib/evalr --create-home evalr; \
	fi

	cp main.awk main.sh playground.sh /var/lib/evalr/
	chown evalr:evalr /var/lib/evalr/{main.awk,main.sh,playground.sh}

	mkdir -p /etc/systemd/system/
	cp evalr.service /etc/systemd/system/
	chown root:root /etc/systemd/system/evalr.service
	systemctl daemon-reload
