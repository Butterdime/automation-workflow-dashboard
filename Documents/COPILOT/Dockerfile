# Main Dockerfile for Webhook Multiplexer Service
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY webhook-multiplexer.js ./
COPY start.sh ./

# Create logs directory
RUN mkdir -p /app/logs

# Make start script executable
RUN chmod +x start.sh

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S copilot -u 1001

# Change ownership
RUN chown -R copilot:nodejs /app

USER copilot

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "webhook-multiplexer.js"]