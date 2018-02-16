FROM node:9.5.0

RUN npm install -g gulp

COPY entrypoint /opt/entrypoint
RUN chmod 755 /opt/entrypoint

ENTRYPOINT ["/opt/entrypoint"]
