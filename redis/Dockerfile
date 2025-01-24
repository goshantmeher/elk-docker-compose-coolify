FROM redis:7-alpine

# Add custom configurations
COPY redis.conf /usr/local/etc/redis/redis.conf

# Use custom config file
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"] 