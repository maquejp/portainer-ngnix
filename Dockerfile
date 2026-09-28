FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY eui-tokens.css /usr/share/nginx/html/eui-tokens.css
COPY style.css /usr/share/nginx/html/style.css
COPY logo-ec-horizontal-mute-white.svg /usr/share/nginx/html/logo-ec-horizontal-mute-white.svg