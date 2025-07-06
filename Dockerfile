FROM php:8.1-fpm
EXPOSE 10000

ARG user=laraveluser
ARG uid=1000

RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libmagickwand-dev \
    mariadb-client

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pecl install imagick \
    && docker-php-ext-enable imagick

RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

WORKDIR /var/www

# Copy application files as root.
COPY . /var/www

# Fix the permissions for /var/www (so $user can write to vendor/)
RUN chown -R $user:$user /var/www

# Switch to the non-root user to run the rest of the steps.
USER $user

# Install dependencies, migrate and seed the database.
RUN composer install && php artisan migrate && php artisan db:seed

# Start Laravel's built-in server.
CMD php artisan serve --host=0.0.0.0 --port=10000
