# HUMAN AI FRAMEWORK Space Dockerfile
FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    curl \
    python3 \
    bash

# Create app directory
WORKDIR /app

# Create startup script
COPY start-framework.sh /app/start.sh
RUN chmod +x /app/start.sh

# Create necessary directories
RUN mkdir -p /app/logs /app/human-ai-framework /shared/copilot-logs /shared/perplexity-spaces

# Expose port for health checks
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/ || exit 1

# Start the service
CMD ["/app/start.sh"]