FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy our configuration script
COPY ./tools/setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh

# Copy custom mariadb config
COPY ./conf/mariadb_config.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

EXPOSE 3306

ENTRYPOINT ["/tmp/setup.sh"]