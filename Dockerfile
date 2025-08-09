FROM node:18-alpine as build

# Security: Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S react -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Security: Install security updates
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

# Security: Remove unnecessary packages and create non-root user
RUN apk del --no-cache curl wget && \
    addgroup -g 1001 -S nginx && \
    adduser -S nginx -u 1001

# Copy built app
COPY --from=build /app/build /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Security: Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Security: Run as non-root user
USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
