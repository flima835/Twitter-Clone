FROM php:8.1-apache

# Instala extensões necessárias para o PHP falar com o MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Define o diretório de trabalho
WORKDIR /var/www/html

# COPIA tudo da pasta atual (onde estão seus .php) para dentro do Apache
COPY . /var/www/html/

# Ajusta permissões para o usuário padrão do Apache (www-data)
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

EXPOSE 80