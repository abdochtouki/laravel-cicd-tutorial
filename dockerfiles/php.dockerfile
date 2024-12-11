# Utiliser l'image PHP-FPM Alpine
FROM php:8.0.20RC1-fpm-alpine3.16

# Définir les arguments pour UID, GID et USER
ARG UID
ARG GID
ARG USER

# Définir les variables d'environnement pour UID, GID et USER
ENV UID=${UID}
ENV GID=${GID}
ENV USER=${USER}

# Créer le répertoire du projet
RUN mkdir -p /var/www/html

WORKDIR /var/www/html

# Supprimer le groupe dialout, car il n'est pas nécessaire
RUN delgroup dialout

# Créer un groupe et un utilisateur avec les UID et GID spécifiés
RUN addgroup -g ${GID} --system ${USER}
RUN adduser -G ${USER} --system -D -s /bin/sh -u ${UID} ${USER}

# Modifier la configuration PHP-FPM pour utiliser l'utilisateur créé
RUN sed -i "s/user = www-data/user = ${USER}/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = ${USER}/g" /usr/local/etc/php-fpm.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Installer les extensions nécessaires (libpng, jpeg, etc.)
RUN apk add --no-cache libpng libpng-dev jpeg-dev

# Configurer et installer l'extension GD avec support JPEG
RUN docker-php-ext-configure gd --enable-gd --with-jpeg
RUN docker-php-ext-install gd

# Installer l'extension EXIF
RUN docker-php-ext-install exif

# Installer l'extension ZIP
RUN apk add --no-cache zip libzip-dev
RUN docker-php-ext-configure zip
RUN docker-php-ext-install zip

# Installer les extensions PDO et PDO_MySQL
RUN docker-php-ext-install pdo pdo_mysql

# Installer l'extension Redis
RUN mkdir -p /usr/src/php/ext/redis \
    && curl -L https://github.com/phpredis/phpredis/archive/5.3.4.tar.gz | tar xvz -C /usr/src/php/ext/redis --strip 1 \
    && echo 'redis' >> /usr/src/php-available-exts \
    && docker-php-ext-install redis

# Installer Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Commande à exécuter par défaut (PHP-FPM)
CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
