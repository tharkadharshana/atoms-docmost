# Stage 1: Base image
FROM node:22-alpine AS base
LABEL org.opencontainers.image.source="https://github.com/docmost/docmost"

# Stage 2: Builder
FROM base AS builder

WORKDIR /app

# Copy all files
COPY . .

# Install pnpm and dependencies
RUN npm install -g pnpm@10.4.0
RUN pnpm install --frozen-lockfile

# Build the application
RUN pnpm build

# Stage 3: Installer
FROM base AS installer

# Install runtime dependencies
RUN apk add --no-cache curl bash

WORKDIR /app

# Copy built apps
COPY --from=builder /app/apps/server/dist /app/apps/server/dist
COPY --from=builder /app/apps/client/dist /app/apps/client/dist
COPY --from=builder /app/apps/server/package.json /app/apps/server/package.json

# Copy built packages
COPY --from=builder /app/packages/editor-ext/dist /app/packages/editor-ext/dist
COPY --from=builder /app/packages/editor-ext/package.json /app/packages/editor-ext/package.json

# Copy root package files
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/pnpm*.yaml /app/

# Copy patches
COPY --from=builder /app/patches /app/patches

# Install pnpm
RUN npm install -g pnpm@10.4.0

# Set permissions
RUN chown -R node:node /app

# Switch to non-root user
USER node

# Install production dependencies
RUN pnpm install --frozen-lockfile --prod

# Create storage directory
RUN mkdir -p /app/data/storage

# Define volume
VOLUME ["/app/data/storage"]

# Expose port
EXPOSE 3000

# Start the application
CMD ["pnpm", "start"]
