FROM docker.io/library/fedora:42

ENV API_USER=upsmon \
    API_PASSWORD= \
    BASEDIR=/etc/ups \
    DESCRIPTION=UPS \
    DRIVER=usbhid-ups \
    GROUP=nut \
    MAXAGE=15 \
    NAME=ups \
    POLLINTERVAL= \
    PORT=auto \
    SDORDER= \
    SECRETNAME=nut-upsd-password \
    SERIAL= \
    SERVER=master \
    USER=nut \
    VENDORID=

RUN dnf update -y && \
    dnf install -y nut

EXPOSE 3493
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
