FROM elastic/filebeat:8.12.1

USER root

# Copy the configuration file
COPY filebeat.yml /usr/share/filebeat/filebeat.yml

# Set permissions
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml && \
    chmod go-w /usr/share/filebeat/filebeat.yml

# Create a directory for logs if needed
RUN mkdir -p /var/log/filebeat && \
    chown -R root:filebeat /var/log/filebeat

USER filebeat 