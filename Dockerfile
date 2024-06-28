FROM "moodlehq/moodle-php-apache:8.0"

ARG MOODLE_VERSION
ARG MOODLE_PLUGIN_RELATIVE_PATH
ARG MOODLE_CODECHECKER_VERSION

RUN apt update && apt install -y wget

RUN chown -R www-data:www-data /var/www /usr/local/src; \
  usermod -u 1000 www-data; \
  groupmod -g 1000 www-data

# make sure apache owns its home dir
RUN chown -R www-data:www-data /var/www

RUN curl -Lo /tmp/moosh.zip https://moodle.org/plugins/download.php/31885/moosh_moodle44_2024050100.zip && \
unzip /tmp/moosh.zip -d /opt && \
ln -s /opt/moosh/moosh.php /usr/local/bin/moosh && \
chmod +x /usr/local/bin/moosh

# install dockerize
RUN curl -sfL $(curl -s https://api.github.com/repos/powerman/dockerize/releases/latest | grep -i /dockerize-$(uname -s)-$(uname -m)\" | cut -d\" -f4) | install /dev/stdin /usr/local/bin/dockerize

USER www-data

WORKDIR /var/www/html

# download moodle
RUN git clone --depth 1 --branch ${MOODLE_VERSION} https://github.com/moodle/moodle.git /var/www/html
COPY config.php /var/www/html/config.php

RUN mkdir -p /var/www/moodledata

RUN ln -s /usr/local/src/ /var/www/html/${MOODLE_PLUGIN_RELATIVE_PATH}

WORKDIR /usr/local/src

USER root

# use dockerize to wait for db server
CMD dockerize -timeout 300s -wait tcp://db:3306 && apache2-foreground
