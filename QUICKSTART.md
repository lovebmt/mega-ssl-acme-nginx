# Quick Start Guide - NGINX Native ACME

## Summary of Changes

Based on official NGINX ACME documentation, I've updated your configuration to use NGINX's native ACME support for automatic SSL certificate management.

### Key Changes:

1. **nginx.conf** - Added ACME configuration
2. **docker-compose.yml** - Updated for ACME module support
3. **Dockerfile** - Created to build NGINX with ACME module
4. **ACME_MIGRATION_GUIDE.md** - Complete migration documentation

## Critical Configuration Points (Per Official Docs)

### 1. Module Loading (nginx.conf)
```nginx
# MUST be at the top level, before events{}
load_module modules/ngx_http_acme_module.so;
```

### 2. DNS Resolver (Required!)
```nginx
http {
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
```
**Why:** ACME needs DNS resolution to communicate with Let's Encrypt servers.

### 3. ACME Configuration
```nginx
    acme_shared_zone zone=acme_shared:1M;
    
    acme_issuer letsencrypt {
        uri         https://acme-v02.api.letsencrypt.org/directory;
        contact     admin@fuvitech.vn;  # UPDATE THIS EMAIL!
        state_path  /var/cache/nginx/acme-letsencrypt;
        accept_terms_of_service;
    }
```

### 4. Port 80 Server Block (CRITICAL!)
```nginx
    # This server block is REQUIRED for ACME HTTP-01 challenges
    server {
        listen 80;
        server_name tb1.fuvitech.vn www.tb1.fuvitech.vn;
        
        location / {
            return 404;  # Don't redirect to HTTPS!
        }
    }
```
**Important:** Port 80 must be accessible from the internet and NOT redirect to HTTPS. The ACME module automatically handles `/.well-known/acme-challenge/` requests.

### 5. HTTPS Server Block
```nginx
    server {
        listen 443 ssl;
        server_name tb1.fuvitech.vn www.tb1.fuvitech.vn;
        
        acme_certificate letsencrypt;
        
        ssl_certificate       $acme_certificate;
        ssl_certificate_key   $acme_certificate_key;
        ssl_certificate_cache max=2;
        
        # ... your proxy configuration ...
    }
```

## Deployment Steps

### Step 1: Update Email Contact
Edit `nginx/nginx.conf` line 19:
```nginx
contact     your-email@fuvitech.vn;  # UPDATE THIS!
```

### Step 2: Build Docker Image
```bash
cd /home/justin/dienmega/tb-ssl
docker build -t nginx-acme:latest .
```

### Step 3: Update docker-compose.yml
Change the image line to use your custom image:
```yaml
services:
  tbwebserver:
    image: nginx-acme:latest  # Change from nginx:latest
```

### Step 4: Deploy
```bash
# Stop current services
docker compose down

# Start with new configuration
docker compose up -d

# Watch the logs for ACME activity
docker compose logs -f tbwebserver
```

## What to Expect

### First Start:
1. NGINX loads the ACME module
2. Requests certificate from Let's Encrypt for tb1.fuvitech.vn and www.tb1.fuvitech.vn
3. Let's Encrypt sends HTTP-01 challenge to port 80
4. ACME module responds to challenge automatically
5. Certificate is issued and installed
6. HTTPS becomes available

### Logs You'll See:
```
acme: requesting certificate for tb1.fuvitech.vn
acme: challenge accepted
acme: certificate issued
```

### Automatic Renewal:
- NGINX monitors certificate expiration
- Automatically renews ~30 days before expiry
- No cron jobs or manual intervention needed!

## Verification

### Check Certificate
```bash
# Test HTTPS
curl -I https://tb1.fuvitech.vn

# View certificate details
echo | openssl s_client -connect tb1.fuvitech.vn:443 -servername tb1.fuvitech.vn 2>/dev/null | openssl x509 -noout -text
```

### Check ACME State
```bash
docker compose exec tbwebserver ls -la /var/cache/nginx/acme-letsencrypt/
```

## Troubleshooting

### "Module not found"
- Ensure Dockerfile built successfully
- Check: `docker compose exec tbwebserver nginx -V | grep acme`

### "Certificate not issued"
- Verify port 80 is accessible from internet
- Check DNS points to your server: `nslookup tb1.fuvitech.vn`
- Check logs: `docker compose logs tbwebserver | grep -i acme`

### "Resolver failed"
- Check DNS resolver works: `docker compose exec tbwebserver ping -c 1 8.8.8.8`
- Try different resolver (e.g., `1.1.1.1` for Cloudflare)

## Important Notes

✅ **Port 80 must be open** - Required for ACME HTTP-01 challenges
✅ **Don't redirect port 80 to HTTPS** - ACME module needs direct access
✅ **DNS must resolve correctly** - Let's Encrypt validates domain ownership
✅ **Automatic renewal** - Happens ~30 days before expiry automatically
✅ **No cron jobs needed** - Everything is handled by NGINX

## Benefits vs Certbot

| Feature | Certbot (Old) | ACME Native (New) |
|---------|---------------|-------------------|
| Renewal | Manual cron job | Automatic |
| Containers | 2 (nginx + certbot) | 1 (nginx only) |
| Complexity | High | Low |
| Failure Point | Multiple | Single |
| Performance | External process | Native |

## Next Steps

1. ✅ Update email in nginx.conf
2. ✅ Build Docker image
3. ✅ Deploy and test
4. ✅ Verify certificate issued
5. ✅ Monitor for 24 hours
6. ✅ Remove old certbot files (after confirmed working)

For complete details, see `ACME_MIGRATION_GUIDE.md`.
