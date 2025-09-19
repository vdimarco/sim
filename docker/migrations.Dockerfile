# Dockerfile for Sim Database Migrations
FROM oven/bun:alpine AS deps

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json bun.lock ./
RUN mkdir -p apps
COPY apps/sim/package.json ./apps/sim/package.json

# Install dependencies
RUN bun install --omit dev --ignore-scripts

FROM oven/bun:alpine AS build
WORKDIR /app

# Copy package files
COPY package.json bun.lock ./
RUN mkdir -p apps
COPY apps/sim/package.json ./apps/sim/package.json

# Install all dependencies
RUN bun install

# Copy source code
COPY . .

FROM oven/bun:alpine AS runner
WORKDIR /app

# Set environment
ENV NODE_ENV=production

# Copy built application
COPY --from=build /app/apps/sim ./apps/sim
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json

# Set working directory to sim app
WORKDIR /app/apps/sim

# Run migrations
CMD ["bun", "run", "db:migrate"]