FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

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
    libssl-dev \
    && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by Laravel
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    tokenizer \
    ctype \
    zip \
    curl \
    opcache

# Install MongoDB PHP extension
RUN pecl install mongodb \
 && docker-php-ext-enable mongodb

# Enable Apache rewrite module
RUN a2enmod rewrite

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application source
COPY . .

# Fix permissions (CRITICAL)
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 755 /var/www/html/storage \
 && chmod -R 755 /var/www/html/bootstrap/cache

# Apache must serve Laravel public folder (CRITICAL)
RUN sed -i 's|/var/www/html|/var/www/html/public|g' \
    /etc/apache2/sites-available/000-default.conf

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-mongodb --no-scripts

# Install Node.js dependencies and build frontend assets
RUN npm install && npm run build

# Configure Apache to respect PORT environment variable
RUN sed -i 's/80/${PORT:-80}/g' /etc/apache2/ports.conf && \
    sed -i 's/:80/:${PORT:-80}/g' /etc/apache2/sites-available/000-default.conf

# Expose Apache port
EXPOSE 80

# Start Apache with PORT environment variable support
CMD ["sh", "-c", "sed -i \"s/Listen 80/Listen $PORT/g\" /etc/apache2/ports.conf && apache2-foreground"]
