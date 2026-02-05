# Dockerfile for Node.js application
FROM node:18-alpine

WORKDIR /app

# Copier les dépendances
COPY package.json .
RUN npm install --production

# Copier le code de l'application
COPY app.js .
COPY index.html .

# IMPORTANT: Copier wizexercice.txt
COPY wizexercice.txt /app/wizexercice.txt

# Exposer le port
EXPOSE 3000

# Variables d'environnement (valeurs par défaut)
ENV MONGODB_URI=""

# Démarrer l'application Node.js directement
CMD ["node", "app.js"]