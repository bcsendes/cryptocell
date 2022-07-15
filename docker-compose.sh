# syntax=docker/dockerfile:1
FROM ubuntu

# Labels
LABEL owner="Balazs Csendes"
LABEL email="balazs.csendes@gmail.com"
LABEL version="1.0"
LABEL services="ssh, node-red, postgresql"
LABEL description="Cryptocell Image"

# Environment variables
ENV CRYPTO=NONE
ENV MARKET=USDT
ENV SYSLOG_IP=10.0.0.2
ENV SYSLOG_PORT=512
ENV PATH=/root:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/14/bin
ENV NODE_PATH=/usr/local/lib/node_modules:/home/cryptogt/.node-red/node_modules
ENV PGDATA=/var/lib/postgresql/data
ENV PGTBSP=/var/lib/postgresql/tbsp
ENV PGVOLUME=/var/lib/postgresql
ENV POSTGRES_DB=cryptogt
ENV POSTGRES_PASSWORD=CryptoGT_2020
ENV POSTGRES_USER=cryptogt
ENV GOSU_VERSION=1.14
ENV LANG=en_US.utf8
ENV PG_MAJOR=14
ENV PG_VERSION=241.pgdg22.04+1

# Docker secret still does not work
# RUN --mount=type=secret,id=cryptogt_password cat /run/secrets/cryptogt_password

RUN apt-get update \
    && apt-get install -y --assume-yes mc \
    && apt-get install -y --assume-yes curl \
    && apt-get install -y --assume-yes net-tools \
    && apt-get install -y --assume-yes openssh-server \
    && apt-get install -y --assume-yes sudo \
    && apt-get install -y --assume-yes coreutils \
    && apt-get install -y --assume-yes nodejs \
    && apt-get install -y --assume-yes npm \
    && apt-get install -y --assume-yes gpg \
    && apt-get install -y --assume-yes dirmngr \
    && apt-get install -y --assume-yes gpg-agent \
    && apt-get install -y --assume-yes dialog \
    && apt-get install -y --assume-yes apt-utils \
    && apt-get install -y --assume-yes wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Creating startup script, download from Github: https://github.com/bcsendes/cryptocell
RUN sudo wget -O /usr/local/bin/start.sh https://raw.githubusercontent.com/bcsendes/cryptocell/main/start.sh && chmod +x /usr/local/bin/start.sh
RUN sudo wget -O /usr/local/bin/docker-entrypoint.sh https://raw.githubusercontent.com/bcsendes/cryptocell/main/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh
RUN sudo wget -O /etc/profile.d/02-env-fix.sh https://raw.githubusercontent.com/bcsendes/cryptocell/main/02-env-fix.sh && chmod +x /etc/profile.d/02-env-fix.sh

# Adding users and groups
RUN set -eux; groupadd -r postgres --gid=999; useradd -p .YB51Bqze2fDo -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres; mkdir -p /var/lib/postgresql; chown -R postgres:postgres /var/lib/postgresql 
RUN useradd -m -p .YB51Bqze2fDo -s /bin/bash cryptogt && usermod -a -G sudo postgres && usermod -a -G sudo cryptogt && usermod -a -G postgres cryptogt

# Finalizing node-red setup
RUN echo 'node-red log init' >> /var/log/node-red.log && sudo chown cryptogt /var/log/node-red.log && mkdir –p /home/cryptogt/.node-red && sudo chown cryptogt /home/cryptogt/.node-red

RUN npm install -g --unsafe-perm node-red

# Install node-red service, download from Github: https://github.com/bcsendes/cryptocell (original script: https://gist.github.com/Belphemur/cf91100f81f2b37b3e94)
RUN sudo wget -O /etc/init.d/node-red.sh https://raw.githubusercontent.com/bcsendes/cryptocell/main/node-red.sh && sudo chmod +x /etc/init.d/node-red.sh && sudo update-rc.d node-red.sh defaults && sed -i 's/USER=root/USER=cryptogt/g' /etc/init.d/node-red.sh

# Install Node-red modules as global modules
RUN sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-buffer-array \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-config \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-loop-processing \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-semaphore \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-dashboard \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-msg-speed \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-dsm \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-postgres-variable \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-queue-gate \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-msg-router \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-os \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-syslog \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-telegrambot \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-diode \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-prometheus-exporter \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-red-contrib-gc-trigger \
   && sudo npm install -g --no-audit --no-update-notifier --no-fund --save --production --engine-strict node-binance-api

# Install Postgresql
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tzdata

RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/UTC /etc/localtime

RUN set -ex; if ! command -v gpg > /dev/null; then apt-get update; apt-get install -y --no-install-recommends gnupg dirmngr ; rm -rf /var/lib/apt/lists/*; fi

RUN set -eux; savedAptMark="$(apt-mark showmanual)"; apt-get update; apt-get install -y --no-install-recommends ca-certificates wget; rm -rf /var/lib/apt/lists/*; dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; export GNUPGHOME="$(mktemp -d)"; gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; gpgconf --kill all; rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; apt-mark auto '.*' > /dev/null; [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; chmod +x /usr/local/bin/gosu; gosu --version; gosu nobody true

RUN set -eux; if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; ! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; fi; apt-get update; apt-get install -y --no-install-recommends locales; rm -rf /var/lib/apt/lists/*; localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN set -eux; apt-get update; apt-get install -y --no-install-recommends libnss-wrapper xz-utils zstd ; rm -rf /var/lib/apt/lists/*

RUN mkdir /docker-entrypoint-initdb.d

RUN set -ex; key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; export GNUPGHOME="$(mktemp -d)"; mkdir -p /usr/local/share/keyrings/; gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; gpg --batch --export --armor "$key" > /usr/local/share/keyrings/postgres.gpg.asc; command -v gpgconf > /dev/null && gpgconf --kill all; rm -rf "$GNUPGHOME"

RUN set -ex; export PYTHONDONTWRITEBYTECODE=1; dpkgArch="$(dpkg --print-architecture)"; aptRepo="[ signed-by=/usr/local/share/keyrings/postgres.gpg.asc ] http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main $PG_MAJOR"; echo "deb $aptRepo" > /etc/apt/sources.list.d/pgdg.list; apt-get update; echo "deb-src $aptRepo" > /etc/apt/sources.list.d/pgdg.list; savedAptMark="$(apt-mark showmanual)"; tempDir="$(mktemp -d)"; chmod -R 777 "$tempDir"; cd "$tempDir"; apt-get update; apt-get install -y --no-install-recommends dpkg-dev; echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list; _update_repo() { dpkg-scanpackages . > Packages; apt-get -o Acquire::GzipIndexes=false update; }; _update_repo; nproc="$(nproc)"; export DEB_BUILD_OPTIONS="nocheck parallel=$nproc"; apt-get build-dep -y postgresql-common pgdg-keyring; apt-get source --compile postgresql-common pgdg-keyring; _update_repo; apt-get build-dep -y "postgresql=$PG_MAJOR+$PG_VERSION"; apt-get source --compile "postgresql=$PG_MAJOR+$PG_VERSION"; apt-mark showmanual | xargs apt-mark auto > /dev/null; apt-mark manual $savedAptMark; ls -lAFh; _update_repo; grep '^Package: ' Packages; cd /; apt-get install -y --no-install-recommends postgresql-common; sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf; apt-get install -y --no-install-recommends "postgresql=$PG_MAJOR+$PG_VERSION"; rm -rf /var/lib/apt/lists/*; if [ -n "$tempDir" ]; then apt-get purge -y --auto-remove; rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; fi; find /usr -name '*.pyc' -type f -exec bash -c 'for pyc; do dpkg -S "$pyc" &> /dev/null || rm -vf "$pyc"; done' -- '{}' +; postgres --version

RUN set -eux; dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 2777 /var/run/postgresql

# Overwrite default Postgresql config script
RUN sudo wget -O /usr/share/postgresql/postgresql.conf.sample https://raw.githubusercontent.com/bcsendes/cryptocell/main/postgresql.conf

# Create data folders
#RUN set -eux; $pgdatamain=$(dirname $PGDATA); mkdir -p "$pgdatamain" && chown -R postgres:postgres "$pgdatamain" && chmod 777 "$pgdatamain"
#RUN set -eux; $pgdatatbsp=$(dirname $PGDATA)"/tbsp"; mkdir -p "$pgdatatbsp" && chown -R postgres:postgres "$pgdatatbsp" && chmod 777 "$pgdatatbsp"
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 750 "$PGDATA"
RUN mkdir -p "$PGTBSP" && chown -R postgres:postgres "$PGTBSP" && chmod 750 "$PGTBSP"

EXPOSE 22 1880 5432

# Volume for Node-red scripts
VOLUME /home/cryptogt/.node-red
# Volume for Postgresql database
VOLUME "$PGVOLUME"

# Script will start ssh server, Node-red and Postgresql (if PGDATA is empty then will create initial database)
ENTRYPOINT ["start.sh"]
