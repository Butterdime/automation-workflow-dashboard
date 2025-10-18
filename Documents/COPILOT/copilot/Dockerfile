# Copilot Agent Dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY server.js ./
COPY config.json ./

# Create logs directory with proper permissions
RUN mkdir -p /app/logs
RUN chmod 755 /app/logs

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S copilot -u 1001

# Change ownership
RUN chown -R copilot:nodejs /app

USER copilot

EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4000/health || exit 1

CMD ["node", "server.js"]