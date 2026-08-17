FROM php:8.1-apache

# Instala extensões necessárias para o PHP falar com o MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Define o diretório de trabalho
WORKDIR /var/www/html

# COPIA tudo da pasta atual para dentro do Apache
COPY . /var/www/html/

# Ajusta permissões
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Instala o Datadog PHP Tracer de forma robusta
RUN curl -LO https://github.com/DataDog/dd-trace-php/releases/latest/download/datadog-setup.php \
    && php datadog-setup.php --php-bin=all \
    && rm datadog-setup.php

EXPOSE 80