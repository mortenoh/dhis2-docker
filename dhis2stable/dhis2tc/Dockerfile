FROM tomcat:8
EXPOSE 8080

ENV DHIS2_HOME /home
VOLUME [ "/home" ]

RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*
RUN curl -sL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    -o /wait-for-it.sh && chmod +x /wait-for-it.sh
RUN curl -sL http://stable.dhis2.org -o /dhis.war
RUN rm -rf /usr/local/tomcat/webapps/* \
    && mv /dhis.war /usr/local/tomcat/webapps/ROOT.war
