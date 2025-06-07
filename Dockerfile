FROM docker.io/library/fedora:42

ENV API_USER=upsmon \
    DESCRIPTION=UPS \
    DRIVER=usbhid-ups \
    GROUP=nut \
    NAME=ups \
    POLLINTERVAL= \
    PORT=auto \
    SDORDER= \
    SECRET=nut-upsd-password \
    SERIAL= \
    SERVER=master \
    USER=nut \
    VENDORID=

RUN dnf update -y && \
    dnf install -y nut

RUN mkdir -p /etc/nut/local

EXPOSE 3493
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
