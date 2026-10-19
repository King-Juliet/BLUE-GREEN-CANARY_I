FROM nginx:1.27-alpine

# Defaults for local runs. In AWS the ECS task definition sets the real values.
ENV REGION_NAME=local \
    COOKIE_DOMAIN=localhost

COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY . /usr/share/nginx/html

EXPOSE 8080