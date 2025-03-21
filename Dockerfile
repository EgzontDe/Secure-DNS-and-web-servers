FROM ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    knot \
    apache2 \
    certbot \
    python3-certbot-apache \
    git \
    net-tools \
    sudo \
    nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable required Apache modules
RUN a2enmod ssl headers rewrite

# Copy configuration files
COPY ./config/knot/knot.conf /etc/knot/knot.conf
COPY ./config/knot/five.secu23.fun.zone /var/lib/knot/five.secu23.fun.zone
COPY ./config/apache2/www.five.secu23.fun.conf /etc/apache2/sites-available/www.five.secu23.fun.conf

# Create necessary directories
RUN mkdir -p /var/www/html/five.secu23.fun
COPY ./www /var/www/html/five.secu23.fun

# Set up SSL (for development environment, you'll need real certs in production)
RUN mkdir -p /etc/letsencrypt/live/www.five.secu23.fun
COPY ./config/ssl /etc/letsencrypt/options-ssl-apache.conf

# Enable site
RUN a2ensite www.five.secu23.fun.conf

# Expose ports
EXPOSE 53/udp 53/tcp 80/tcp 443/tcp

# Copy entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]