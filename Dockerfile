FROM python:alpine

# The ElastAlert version to use. Configurable on build time. 
ARG ELASTALERT_VERSION=0.2.4

# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/elastalert
# Set this environment variable to True to set timezone on container start.
ENV SET_CONTAINER_TIMEZONE False
# Default container timezone as found under the directory /usr/share/zoneinfo/.
ENV CONTAINER_TIMEZONE US/Eastern
# Directory holding configuration for Elastalert and Supervisor.
ENV CONFIG_DIR ${ELASTALERT_HOME}/config
# Elastalert rules directory.
ENV RULES_DIRECTORY ${ELASTALERT_HOME}/rules
# Elastalert configuration file path in configuration directory.
ENV ELASTALERT_CONFIG ${CONFIG_DIR}/elastalert_config.yaml
# Directory to which Elastalert and Supervisor logs are written.
ENV LOG_DIR ${ELASTALERT_HOME}/logs
# Alias, DNS or IP of Elasticsearch host to be queried by Elastalert. Set in default Elasticsearch configuration file.
ENV ELASTICSEARCH_HOST logging-es.openshift-logging.svc
# Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
ENV ELASTICSEARCH_PORT 9200
# Use TLS to connect to Elasticsearch (True or False)
ENV ELASTICSEARCH_TLS True
# Verify TLS
ENV ELASTICSEARCH_TLS_VERIFY True
# ElastAlert writeback index
ENV ELASTALERT_INDEX elastalert_status

RUN apk --update upgrade && \
    apk add gcc libffi-dev musl-dev python3-dev openssl-dev tzdata libmagic && \
    rm -rf /var/cache/apk/*

RUN pip install elastalert==${ELASTALERT_VERSION} && \
    apk del gcc libffi-dev musl-dev python3-dev openssl-dev

RUN mkdir -p ${ELASTALERT_HOME} && \
    mkdir -p "${CONFIG_DIR}" && \
    mkdir -p "${LOG_DIR}" && \
    mkdir -p "${RULES_DIRECTORY}" && \
    mkdir -p /var/empty

WORKDIR "${ELASTALERT_HOME}"

# Copy the script used to launch the Elastalert when a container is started.
COPY configuration/start-elastalert.sh ${ELASTALERT_HOME}/
# Make the start-script executable.
RUN chmod +x ${ELASTALERT_HOME}/start-elastalert.sh

# Define mount points.
VOLUME [ "${CONFIG_DIR}", "${RULES_DIRECTORY}", "${LOG_DIR}"]

# Launch Elastalert when a container is started.
CMD ["${ELASTALERT_HOME}/start-elastalert.sh"]
