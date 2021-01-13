FROM ubuntu:bionic
LABEL maintainer Brady Wetherington <uberbrady@gmail.com>

RUN export DEBIAN_FRONTEND=noninteractive; \
      export DEBCONF_NONINTERACTIVE_SEEN=true; \
      echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections; \
      echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections; \
      apt-get update -qqy \
      && apt-get install -qqy --no-install-recommends \
      apt-utils \
      apache2 \
      apache2-bin \
      libapache2-mod-php7.2 \
      php7.2-curl \
      php7.2-ldap \
      php7.2-mysql \
      php7.2-gd \
      php7.2-xml \
      php7.2-mbstring \
      php7.2-zip \
      php7.2-bcmath \
      patch \
      curl \
      wget  \
      vim \
      git \
      cron \
      mysql-client \
      supervisor \
      cron \
      gcc \
      make \
      autoconf \
      libc-dev \
      pkg-config \
      libmcrypt-dev \
      php7.2-dev \
      ca-certificates \
      unzip \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN curl -L -O https://github.com/pear/pearweb_phars/raw/master/go-pear.phar
RUN php go-pear.phar

RUN pecl install mcrypt-1.0.2

RUN bash -c "echo extension=/usr/lib/php/20170718/mcrypt.so > /etc/php/7.2/mods-available/mcrypt.ini"

RUN phpenmod mcrypt
RUN phpenmod gd
RUN phpenmod bcmath

RUN sed -i 's/variables_order = .*/variables_order = "EGPCS"/' /etc/php/7.2/apache2/php.ini
RUN sed -i 's/variables_order = .*/variables_order = "EGPCS"/' /etc/php/7.2/cli/php.ini

RUN useradd -m --uid 1000 --gid 50 docker

RUN echo export APACHE_RUN_USER=docker >> /etc/apache2/envvars
RUN echo export APACHE_RUN_GROUP=staff >> /etc/apache2/envvars

COPY docker/000-default.conf /etc/apache2/sites-enabled/000-default.conf
RUN mkdir -p /var/lib/snipeit/ss

COPY . /var/www/html

WORKDIR /var/www/html
COPY docker/docker.env /var/www/html/.env

RUN chown -R docker /var/www/html

RUN \
      rm -r "/var/www/html/storage/private_uploads" && ln -fs "/var/lib/snipeit/data/private_uploads" "/var/www/html/storage/private_uploads" \
      && rm -rf "/var/www/html/public/uploads" && ln -fs "/var/lib/snipeit/data/uploads" "/var/www/html/public/uploads" \
      && rm -r "/var/www/html/storage/app/backups" && ln -fs "/var/lib/snipeit/dumps" "/var/www/html/storage/app/backups" \
      && mkdir -p "/var/lib/snipeit/keys" && ln -fs "/var/lib/snipeit/keys/oauth-private.key" "/var/www/html/storage/oauth-private.key" \
      && ln -fs "/var/lib/snipeit/keys/oauth-public.key" "/var/www/html/storage/oauth-public.key" \
      && chown docker "/var/lib/snipeit/keys/" \
      && chmod +x /var/www/html/artisan \
      && echo "Finished setting up application in /var/www/html"

RUN \
      echo "Listen 8080" >> /etc/apache2/ports.conf && \
      a2enmod rewrite

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
USER docker
RUN composer install --no-dev --working-dir=/var/www/html
USER root
EXPOSE 8080
VOLUME ["/var/lib/snipeit"]

COPY docker/startup.sh docker/supervisord.conf /
COPY docker/supervisor-exit-event-listener /usr/bin/supervisor-exit-event-listener
RUN chmod +x /startup.sh /usr/bin/supervisor-exit-event-listener

CMD ["/startup.sh"]
