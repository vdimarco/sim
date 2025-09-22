# Use Bun base image for better performance and compatibility
FROM oven/bun:alpine AS base

# ========================================
# Dependencies Stage: Install Dependencies
# ========================================
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install turbo globally
RUN bun install -g turbo

# Copy package files
COPY package.json bun.lock ./
RUN mkdir -p apps
COPY apps/sim/package.json ./apps/sim/package.json

# Install dependencies
RUN bun install --omit dev --ignore-scripts

# ========================================
# Builder Stage: Build the Application
# ========================================
FROM base AS builder
WORKDIR /app

# Copy package files
COPY package.json bun.lock ./
RUN mkdir -p apps
COPY apps/sim/package.json ./apps/sim/package.json

# Install ALL dependencies (including dev dependencies for turbo)
RUN bun install

# Copy source code
COPY . .

# Build the application
WORKDIR /app/apps/sim
RUN bun run build

# ========================================
# Runner Stage: Run the Application
# ========================================
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Copy built application
COPY --from=builder /app/apps/sim ./apps/sim
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Set working directory to sim app
WORKDIR /app/apps/sim

# Expose port
EXPOSE 3000

# Start the application
CMD ["bun", "run", "start"]
