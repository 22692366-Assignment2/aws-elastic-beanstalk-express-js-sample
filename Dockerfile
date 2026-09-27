# The assignment requires Node.js 16 for the application environment.
FROM node:16-alpine

# Set production mode to reduce unnecessary runtime behaviour.
ENV NODE_ENV=production

# Use a dedicated application directory.
WORKDIR /usr/src/app

# Copy dependency manifests first to improve Docker layer caching.
COPY --chown=node:node package*.json ./

# Install only production dependencies and clear the npm cache.
RUN npm ci --omit=dev && npm cache clean --force

# Copy only the application file required at runtime.
COPY --chown=node:node app.js ./

# Run the application as the existing unprivileged node user.
USER node

EXPOSE 8080

CMD ["node", "app.js"]
