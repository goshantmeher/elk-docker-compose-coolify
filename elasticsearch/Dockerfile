FROM docker.elastic.co/elasticsearch/elasticsearch:8.12.1

USER root

# Add any custom configurations if needed
COPY elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
RUN chown elasticsearch:elasticsearch /usr/share/elasticsearch/config/elasticsearch.yml

USER elasticsearch 