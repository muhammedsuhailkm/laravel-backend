# ================================
# Base image: PHP 8.2 + Apache
# ================================
FROM php:8.2-apache

# ================================
# Set working directory
# ================================
WORKDIR /var/www/html

# ================================
# Install system dependencies
# ================================
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
    nodejs \
    npm \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ================================
# Install PHP extensions
# ================================
RUN docker-php-ext-install \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd

# ================================
# Install MongoDB PHP extension
# ================================
RUN pecl install mongodb-1.21.2 \
 && docker-php-ext-enable mongodb

# ================================
# Enable Apache rewrite module
# ================================
RUN a2enmod rewrite

# ================================
# Install Composer
# ================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ================================
# Copy application files
# ================================
COPY . .

# ================================
# Fix permissions (CRITICAL)
# ================================
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 755 /var/www/html/storage \
 && chmod -R 755 /var/www/html/bootstrap/cache

# ================================
# Configure Apache to serve /public
# ================================
RUN sed -i 's|/var/www/html|/var/www/html/public|g' \
    /etc/apache2/sites-available/000-default.conf

# ================================
# Install PHP dependencies (prod)
# ================================
RUN composer install --no-dev --optimize-autoloader

# ================================
# Build frontend assets (Vite)
# ================================
RUN npm install && npm run build

# ================================
# Expose port (Render expects 80)
# ================================
EXPOSE 80

# ================================
# Start Apache
# ================================
CMD ["apache2-foreground"]
