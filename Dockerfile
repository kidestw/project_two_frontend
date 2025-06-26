# --- Stage 1: Build the Next.js application ---
# Use a Node.js image as the base for building
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and yarn.lock/package-lock.json to leverage Docker cache
# This allows npm install to be cached if dependencies haven't changed
COPY package.json yarn.lock* package-lock.json* ./

# Install dependencies. Use yarn if yarn.lock exists, otherwise npm.
# IMPORTANT: Added --force to npm ci to bypass peer dependency conflicts
# This is a workaround for issues with new React 19 RC versions and older libraries.
# In a stable environment, you would aim to update react-apexcharts to a version
# explicitly compatible with your React version.
RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci --force; \
    else npm install --force; fi

# Copy the rest of your Next.js application code
COPY . .

# Build the Next.js application for production
# 'next build' generates optimized production build in the .next folder
RUN npm run build

# --- Stage 2: Serve the Next.js application with a lightweight image ---
# Using a smaller Node.js runtime image for the final production image
FROM node:20-alpine AS runner

# Set the working directory
WORKDIR /app

# Set environment variables for Next.js production mode
ENV NODE_ENV=production

# Copy necessary files from the builder stage
# Copy node_modules (production dependencies only)
COPY --from=builder /app/node_modules ./node_modules
# Copy the .next folder (production build output)
COPY --from=builder /app/.next ./.next
# Copy public assets
COPY --from=builder /app/public ./public

# Copy package.json to run start script
COPY package.json ./package.json

# Expose the port Next.js listens on (default is 3000)
EXPOSE 3000

# Command to run the Next.js application in production mode
CMD ["npm", "run", "start"]
