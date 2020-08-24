FROM centos/python-36-centos7

# The ElastAlert version to use. Configurable on build time. 
ARG ELASTALERT_VERSION=v0.2.4

# Elastalert home directory full path.
ENV ELASTALERT_HOME=/opt/elastalert
# Set this environment variable to True to set timezone on container start.
ENV SET_CONTAINER_TIMEZONE False
# Default container timezone as found under the directory /usr/share/zoneinfo/.
ENV CONTAINER_TIMEZONE US/Eastern
# URL from which to download Elastalert.
ENV ELASTALERT_URL https://github.com/Yelp/elastalert/archive/$ELASTALERT_VERSION.zip
# Directory holding configuration for Elastalert and Supervisor.
ENV CONFIG_DIR $ELASTALERT_HOME/config
# Elastalert rules directory.
ENV RULES_DIRECTORY $ELASTALERT_HOME/rules
# Elastalert configuration file path in configuration directory.
ENV ELASTALERT_CONFIG ${CONFIG_DIR}/elastalert_config.yaml
# Supervisor configuration file for Elastalert.
ENV ELASTALERT_SUPERVISOR_CONF ${CONFIG_DIR}/elastalert_supervisord.conf
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

# WORKDIR /opt
USER root

# Install software required for Elastalert
RUN INSTALL_PKGS="python-devel" && \
    yum -y update && \
    yum -y install ${INSTALL_PKGS} && \
    yum -q clean all

USER 1000

# Download Elastalert.
RUN wget -O elastalert.zip $ELASTALERT_URL && \
    unzip elastalert.zip && \
    rm elastalert.zip && \
    mv elastalert* "${ELASTALERT_HOME}"

WORKDIR "${ELASTALERT_HOME}"

# Install Elastalert.
RUN pip install "setuptools>=11.3" && python setup.py install && \
# Install Supervisor.
    easy_install supervisor && \
# Create directories. The /var/empty directory is used by openntpd.
    mkdir -p "${CONFIG_DIR}" && \
    mkdir -p "${RULES_DIRECTORY}" && \
    mkdir -p "${LOG_DIR}" && \
    mkdir -p /var/empty && \

# Copy the script used to launch the Elastalert when a container is started.
COPY ./start-elastalert.sh ${ELASTALERT_HOME}/
# Make the start-script executable.
RUN chmod +x ${ELASTALERT_HOME}/start-elastalert.sh

# # Create default user and change ownership of files
# RUN useradd -u 1000 -r -g 0 -m -d $HOME -s /sbin/nologin -c "elastalert user" elastalert && \
#     cp -r /etc/skel/. $HOME && \
#     chown -R elastalert:0 $HOME && \
#     fix-permissions $HOME && \
#     fix-permissions /opt/app-root

# # Create dirs
# RUN chmod +x $ELASTALERT_HOME/run.sh && \
#     ln -s $ELASTALERT_HOME/run.sh $HOME/run.sh && \
#     mkdir $ELASTALERT_HOME/rules && \
#     mkdir $ELASTALERT_HOME/config

# Define mount points.
VOLUME [ "${CONFIG_DIR}", "${RULES_DIRECTORY}", "${LOG_DIR}"]

# Install workaround
# RUN . /opt/app-root/etc/scl_enable && \
#     pip install --upgrade pip && \
#     pip install --upgrade setuptools && \
#     pip install elastalert

# switch to elastalert
# USER 1000

# Launch Elastalert when a container is started.
CMD ["${ELASTALERT_HOME}/start-elastalert.sh"]
