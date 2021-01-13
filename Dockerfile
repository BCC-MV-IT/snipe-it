FROM composer:1.9.0 as build
WORKDIR /app
COPY . /app
RUN composer global require hirak/prestissimo && composer install

VOLUME ["/var/lib/snipeit"]

FROM php:7.3-apache-stretch
RUN docker-php-ext-install pdo pdo_mysql

EXPOSE 8080
COPY --from=build /app /var/www/
COPY build/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY .env.production /var/www/.env
COPY effortless-edge-296714-56c9d64859f6.json /var/www/effortless-edge-296714-56c9d64859f6.json
RUN chmod 777 -R /var/www/storage/ && \
        echo "Listen 8080" >> /etc/apache2/ports.conf && \
        chown -R www-data:www-data /var/www/ && \
        a2enmod rewrite
	
COPY docker/startup.sh docker/supervisord.conf /
COPY docker/supervisor-exit-event-listener /usr/bin/supervisor-exit-event-listener
RUN chmod +x /startup.sh /usr/bin/supervisor-exit-event-listener

CMD ["/startup.sh"]
