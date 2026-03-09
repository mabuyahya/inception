FROM alpine:3.18

RUN apk update && apk add --no-cache \
    nginx \
    openssl

# Generate a self-signed SSL certificate
# (42 project requires HTTPS with TLSv1.2 or TLSv1.3)
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=MA/ST=Khouribga/L=Khouribga/O=42/OU=42/CN=mabuyahy.42.fr"

# Copy nginx configuration
COPY ./conf/nginx.conf /etc/nginx/http.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]