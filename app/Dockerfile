# Stage 1: Build Node.js dependencies
FROM node:18-alpine AS node-builder

WORKDIR /app

# Copier package.json et installer les dépendances
COPY package.json .
RUN npm install --production

# Copier le code de l'application
COPY app.js .
COPY index.html .

# Stage 2: Image finale avec NGINX + Node.js
FROM nginx:1.24-alpine

# Installer Node.js dans l'image NGINX
RUN apk add --no-cache nodejs npm supervisor

# Créer les répertoires nécessaires
RUN mkdir -p /app /var/log/supervisor

# Copier l'application Node.js depuis le builder
COPY --from=node-builder /app /app

# Copier la configuration NGINX
COPY nginx.conf /etc/nginx/nginx.conf

# Copier le fichier HTML dans le répertoire NGINX
COPY index.html /usr/share/nginx/html/

# IMPORTANT: Copier le fichier wizexercise.txt avec votre nom
COPY wizexercice.txt /app/wizexercice.txt

# Configuration de Supervisor pour gérer NGINX + Node.js
RUN echo $'[supervisord]\n\
nodaemon=true\n\
logfile=/var/log/supervisor/supervisord.log\n\
pidfile=/var/run/supervisord.pid\n\
\n\
[program:nginx]\n\
command=nginx -g "daemon off;"\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:nodejs]\n\
command=node /app/app.js\n\
directory=/app\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
environment=MONGODB_URI="%(ENV_MONGODB_URI)s"' > /etc/supervisord.conf

EXPOSE 80

# Lancer Supervisor qui gérera NGINX et Node.js
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
