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
    nodejs \
    npm \
    libssl-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install MongoDB PHP extension (latest version)
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Enable Apache modules
RUN a2enmod rewrite

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application code
COPY . .

# Set proper permissions and configure git
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R g+w storage bootstrap/cache && \
    git config --global --add safe.directory /var/www/html

# Install PHP dependencies (skip scripts to avoid conflicts)
RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-mongodb --no-scripts

# Install Node.js dependencies
RUN npm install

# Expose port
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
