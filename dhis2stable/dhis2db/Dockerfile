FROM postgres:10

ENV POSTGRES_USER dhis
ENV POSTGRES_PASSWORD dhis
ENV POSTGRES_DB dhis

RUN apt-get update \
    && apt-get install -y postgresql-10-postgis-2.4 curl \
    && rm -rf /var/lib/apt/lists/*
RUN curl -sL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    -o /wait-for-it.sh && chmod +x /wait-for-it.sh
