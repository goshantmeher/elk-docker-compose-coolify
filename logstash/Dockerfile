FROM docker.elastic.co/logstash/logstash:8.12.1

# Copy configurations
COPY config/logstash.yml /usr/share/logstash/config/logstash.yml
COPY pipeline /usr/share/logstash/pipeline

# Add any custom configurations if needed
USER root
RUN chown -R logstash:logstash /usr/share/logstash/config/logstash.yml \
    && chown -R logstash:logstash /usr/share/logstash/pipeline
USER logstash 