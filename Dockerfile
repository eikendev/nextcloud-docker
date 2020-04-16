FROM nextcloud:apache

ENV APACHE_PORT=8080 \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_DOCUMENT_ROOT=/var/www/app

# This is not strictly necessary, but makes it easier for users to expose all
# ports automatically.
EXPOSE ${APACHE_PORT}

WORKDIR ${APACHE_DOCUMENT_ROOT}

# Set a different root for Apache, see https://hub.docker.com/_/php/. To enable
# logging for a non-root user, the user has to be added to the tty group as
# described in
# https://github.com/moby/moby/issues/31243#issuecomment-406879017.
# Additionally, the default log files are explicitly set to stdout and stderr.
RUN set -ex \
	&& usermod -a -G tty ${APACHE_RUN_USER} \
	&& mkdir -p ${APACHE_DOCUMENT_ROOT} \
	&& sed -i 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
	&& sed -i "s/Listen 80/Listen ${APACHE_PORT}/g" /etc/apache2/ports.conf \
	&& sed -i "s/:80>/:${APACHE_PORT}>/g" /etc/apache2/sites-available/000-default.conf \
	&& sed -i 's!ErrorLog.*!ErrorLog /dev/stderr!g' /etc/apache2/*.conf /etc/apache2/sites-available/*.conf \
	&& sed -i 's!CustomLog.*!CustomLog /dev/stdout common!g' /etc/apache2/*.conf /etc/apache2/sites-available/*.conf \
	&& sed -i 's!/var/www/html!/var/www/app!g' /var/spool/cron/crontabs/*

# Copy the installation to the new document root. We adjust the permissions so
# that only root can change them, but others can read them.
RUN set -ex \
	&& rsync -rlD --delete --exclude-from=/upgrade.exclude /usr/src/nextcloud/ ./ \
	&& rsync -rlD /usr/src/nextcloud/version.php ./ \
	&& chown -R root:www-data . \
	&& chown -R www-data:www-data ./apps \
	&& find . -type f -print0 | xargs -0 chmod 0640 \
	&& find . -type d -print0 | xargs -0 chmod 0750 \
	&& for dir in config data custom_apps themes; \
		do mkdir -p /volume/$dir; \
		ln -s /volume/$dir ./$dir; \
		chown www-data:www-data /volume/$dir; \
		chmod 750 /volume/$dir; \
		done

VOLUME /volume/config /volume/data /volume/custom_apps /volume/themes

# Set a custom entrypoint.
COPY entrypoint.sh /entrypoint.sh
RUN chmod 540 /entrypoint.sh
