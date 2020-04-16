#!/usr/bin/env sh

set -o errexit
set -o xtrace

WWWUSER='www-data'

directory_empty() {
	[ -z "$(ls -A "$1/")" ]
}

run_as() {
	if [ "$(id -u)" = 0 ]; then
		su -p -s /bin/sh -c "$1" -- "$WWWUSER"
	else
		sh -c "$1"
	fi
}

if expr "$1" : "apache" 1>/dev/null; then
	if [ -n "${APACHE_DISABLE_REWRITE_IP+x}" ]; then
		a2disconf remoteip
	fi
fi

for dir in config data custom_apps themes; do
	chown "$WWWUSER" /volume/$dir
	chmod -R u+rw /volume/$dir
done

if expr "$1" : "apache" 1>/dev/null; then
	# Enable Redis if available.
	if [ -n "${REDIS_HOST+x}" ]; then
		{
			echo 'session.save_handler = redis'
			if [ -n "${REDIS_HOST_PASSWORD+x}" ]; then
				echo "session.save_path = \"tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}?auth=${REDIS_HOST_PASSWORD}\""
			else
				echo "session.save_path = \"tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}\""
			fi
		} > /usr/local/etc/php/conf.d/redis-session.ini
	else
		rm -f /usr/local/etc/php/conf.d/redis-session.ini
	fi

	if directory_empty "/volume/config"; then
		# Copy the configuration to the new environment.
		for dir in config themes; do
			if directory_empty "/volume/$dir"; then
				cp -r "/usr/src/nextcloud/$dir/"* "./$dir"
			fi
		done
	else
		# Upgrade the database.
		run_as 'php occ upgrade'

		# Enable maintenance mode.
		run_as 'php occ maintenance:mode --on'

		# Add missing indices in database.
		run_as 'php occ db:add-missing-indices'

		# Convert database columns to big int.
		run_as 'php occ db:convert-filecache-bigint --no-interaction'

		# Disable maintenance.
		run_as 'php occ maintenance:mode --off'
	fi

	exec su -p -s /bin/sh -c "$@" -- "$WWWUSER"
fi

exec "$@"
