FROM nginx:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    iputils-ping \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Update CA certificates
RUN update-ca-certificates

# Add NGINX repository signing key
RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    -o /usr/share/keyrings/nginx-archive-keyring.gpg

# Add NGINX mainline repository
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/mainline/debian `cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2` nginx" \
    > /etc/apt/sources.list.d/nginx.list

# Install ACME module
RUN apt-get update && apt-get install -y nginx-module-acme \
    && rm -rf /var/lib/apt/lists/*

# Create ACME cache directory
RUN mkdir -p /var/cache/nginx/acme-letsencrypt && \
    chmod 755 /var/cache/nginx/acme-letsencrypt

EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
