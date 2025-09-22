# Dockerfile for Sim Database Migrations
FROM oven/bun:alpine AS base

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json bun.lock ./
RUN mkdir -p apps
COPY apps/sim/package.json ./apps/sim/package.json

# Install all dependencies
RUN bun install

# Copy source code
COPY . .

# Set working directory to sim app
WORKDIR /app/apps/sim

# Run migrations
CMD ["bun", "run", "db/migrate.js"]