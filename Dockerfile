# Use PHP 8.2 with Apache
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
    libpq-dev \
    libssl-dev \
    pkg-config \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install MongoDB PHP extension
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Copy the entire application
COPY . .

# Install PHP dependencies (without dev dependencies for production)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Set proper ownership
RUN chown -R www-data:www-data /var/www/html

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache DocumentRoot to point to Laravel's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Update Apache configuration to allow .htaccess overrides
RUN echo '<Directory /var/www/html/public>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# Set proper permissions for Laravel directories
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Create startup script that runs Laravel optimization commands
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting Laravel application..."\n\
\n\
# Run Laravel optimization commands\n\
php artisan config:cache\n\
php artisan route:cache\n\
php artisan view:cache\n\
\n\
# Run migrations (optional - remove if you prefer manual migrations)\n\
php artisan migrate --force\n\
\n\
echo "Laravel is ready!"\n\
\n\
# Start Apache in foreground\n\
apache2-foreground' > /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start the application
CMD ["/usr/local/bin/start.sh"]