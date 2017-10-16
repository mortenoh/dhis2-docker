FROM tomcat:8-alpine
EXPOSE 8080

ENV DHIS2_HOME /home
VOLUME [ "/home" ]

RUN apk update && apk add curl
RUN curl -sL https://raw.githubusercontent.com/Eficode/wait-for/master/wait-for \
    -o /wait-for && chmod +x /wait-for
RUN curl -sL http://stable.dhis2.org -o /dhis.war
RUN rm -rf /usr/local/tomcat/webapps/* \
    && mv /dhis.war /usr/local/tomcat/webapps/ROOT.war
