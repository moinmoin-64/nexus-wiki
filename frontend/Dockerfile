# Frontend Dockerfile

FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Expose port
EXPOSE 5173

# Start Vite dev server
CMD ["npm", "run", "dev"]
