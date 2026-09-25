FROM node:24-alpine

LABEL maintainer="Imarc <info@imarc.com>"

RUN npm install -g gulp

COPY entrypoint /opt/entrypoint
RUN chmod 755 /opt/entrypoint

ENTRYPOINT ["/opt/entrypoint"]
