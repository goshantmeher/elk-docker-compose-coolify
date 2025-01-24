FROM docker.elastic.co/elasticsearch/elasticsearch:8.12.1

# Add any custom configurations if needed
COPY elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml

# Add setup script
COPY setup-users.sh /usr/local/bin/setup-users.sh
RUN chmod +x /usr/local/bin/setup-users.sh

USER root
RUN chown elasticsearch:elasticsearch /usr/local/bin/setup-users.sh
USER elasticsearch

CMD ["/usr/local/bin/setup-users.sh"] 