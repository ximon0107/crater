# Use PHP 8.1 FPM as the base image
FROM php:8.1-fpm

# Expose Laravel development server port
EXPOSE 10000

# Set build arguments for user creation
ARG user=laraveluser
ARG uid=1000

# Install system dependencies
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

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Imagick PHP extension
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install required PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd

# Copy Composer from official Composer image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create non-root user for security
RUN useradd -G www-data,root -u $uid -d /home/$user $user && \
    mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www

# Switch to non-root user
USER $user

# Copy project files into the container
COPY . /var/www

# Install PHP dependencies and run Laravel migrations/seeding non-interactively
RUN composer install && php artisan migrate --force && php artisan db:seed --force

# Start Laravel development server on container start
CMD php artisan serve --host=0.0.0.0 --port=10000
