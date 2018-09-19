FROM richarvey/nginx-php-fpm:latest

LABEL maintainer="Peter Sammer"

ARG ESPO_VERSION=5.4.3

ENV php_vars /usr/local/etc/php/conf.d/docker-vars.ini
ENV PROJECT_PATH=/var/www/espocrm

# Adjust php-fpm config
RUN echo "max_execution_time = 180" >> ${php_vars} && \
    echo "max_input_time = 180" >> ${php_vars} && \
    echo "memory_limit = 256M" >> ${php_vars}

# Install dependencies for php
RUN apk add --no-cache \
        			libmcrypt-dev \
        			libltdl imap-dev zlib-dev libzip-dev
RUN docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-configure imap --with-imap --with-imap-ssl \
    && docker-php-ext-install imap

# Set nginx config
COPY nginx.default.conf /etc/nginx/sites-available/default.conf

WORKDIR /tmp
RUN wget https://www.espocrm.com/downloads/EspoCRM-$ESPO_VERSION.zip && \
    unzip /tmp/EspoCRM-$ESPO_VERSION.zip -d /tmp

RUN cp -a /tmp/EspoCRM-$ESPO_VERSION/. $PROJECT_PATH/ && rm -rf /tmp/EspoCRM-$ESPO_VERSION

WORKDIR /var/www/espocrm

# Set correct permission as described in EspoCRM documentation
RUN cd $PROJECT_PATH \
    && find . -type d -exec chmod 755 {} + && find . -type f -exec chmod 644 {} +; \
    find data custom -type d -exec chmod 775 {} + && find data custom -type f -exec chmod 664 {} +; \
    chown -R nginx:nginx .

# Install cronjob for EspoCRM
RUN echo '* * * * * cd /var/www/espocrm; /usr/local/bin/php -f cron.php > /dev/null 2>&1' >> /etc/crontabs/root

EXPOSE 80

CMD ["sh","-c","crond && /start.sh"]
