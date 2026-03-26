FROM alpine:3.18

RUN apk update && apk add --no-cache \
    php81 \
    php81-fpm \
    php81-mysqli \
    php81-json \
    php81-curl \
    php81-dom \
    php81-exif \
    php81-fileinfo \
    php81-mbstring \
    php81-openssl \
    php81-xml \
    php81-zip \
    php81-gd \
    php81-iconv \
    php81-intl \
    php81-phar \
    php81-tokenizer \
    php81-ctype \
    wget \
    mariadb-client

RUN sed -i 's/memory_limit = 128M/memory_limit = 512M/' /etc/php81/php.ini
# Download WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Create wordpress directory and give nobody ownership
RUN mkdir -p /var/www/html/wordpress && \
    chown -R nobody:nobody /var/www/html/wordpress

# Configure PHP-FPM
COPY ./conf/php_fpm.config /etc/php81/php-fpm.d/www.conf

# Copy setup script
COPY ./tools/setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh

WORKDIR /var/www/html/wordpress

EXPOSE 9000

ENTRYPOINT ["/tmp/setup.sh"]