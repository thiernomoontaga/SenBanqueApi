# ============================
# Étape 1 : Build avec Composer
# ============================
FROM composer:2.6 AS composer-build

WORKDIR /app

# Copier le code source
COPY . .

# Installer Swagger + dépendances Laravel sans exécuter les scripts Artisan
RUN composer require "zircote/swagger-php:^4.0" --no-scripts --no-interaction --prefer-dist \
    && composer install --no-scripts --optimize-autoloader --no-interaction --prefer-dist


# ============================
# Étape 2 : Image d’exécution PHP
# ============================
FROM php:8.3-fpm-alpine

# Installer les extensions PHP nécessaires
RUN apk add --no-cache postgresql-dev oniguruma-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring

# Créer un utilisateur non-root
RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

# Définir le répertoire de travail
WORKDIR /var/www/html

# Copier les fichiers depuis le build Composer
COPY --from=composer-build /app /var/www/html

# Créer les répertoires nécessaires et ajuster les permissions
RUN mkdir -p storage/framework/{cache,data,sessions,testing,views} \
    && mkdir -p storage/logs bootstrap/cache \
    && chown -R laravel:laravel /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Changer d’utilisateur
USER laravel

# Exposer le port HTTP
EXPOSE 8000

# ============================
# Lancer Laravel
# ============================
# ⚠ Ici on force le cast du PORT en entier pour éviter l'erreur `string + int`
CMD php artisan serve --host=0.0.0.0 --port=$((${PORT:-8000}))

