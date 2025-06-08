#! /bin/sh -e

# adapted from https://github.com/instantlinux/docker-tools/tree/main/images/nut-upsd

BASEDIR=${BASEDIR:-/etc/ups}

if [ -d /run/secrets ] && [ -s "/run/secrets/$SECRETNAME" ]; then
  API_PASSWORD=$(cat "/run/secrets/$SECRETNAME")
fi

if [ ! -e "$BASEDIR/.setup" ]; then
  if [ -e "$BASEDIR/local/ups.conf" ]; then
    cp "$BASEDIR/local/ups.conf" "$BASEDIR/ups.conf"
  else
    if [ -z "$SERIAL" ] && [ "$DRIVER" = usbhid-ups ] ; then
      echo "** This container may not work without setting for SERIAL **"
    fi
    cat <<EOF >>"$BASEDIR/ups.conf"
[$NAME]
        driver = $DRIVER
        port = $PORT
        desc = "$DESCRIPTION"
EOF
    if [ -n "$SERIAL" ]; then
      echo "        serial = \"$SERIAL\"" >> $BASEDIR/ups.conf
    fi
    if [ -n "$POLLINTERVAL" ]; then
      echo "        pollinterval = $POLLINTERVAL" >> $BASEDIR/ups.conf
    fi
    if [ -n "$VENDORID" ]; then
      echo "        vendorid = $VENDORID" >> $BASEDIR/ups.conf
    fi
    if [ -n "$SDORDER" ]; then
      echo "        sdorder = $SDORDER" >> $BASEDIR/ups.conf
    fi
  fi
  if [ "${MAXAGE:-15}" -ne 15 ]; then
      sed -i -e "s/^[# ]*MAXAGE [0-9]\+/MAXAGE $MAXAGE/" "$BASEDIR/upsd.conf"
  fi
  if [ -e $BASEDIR/local/upsd.conf ]; then
    cp "$BASEDIR/local/upsd.conf" "$BASEDIR/upsd.conf"
  else
    cat <<EOF >>"$BASEDIR/upsd.conf"
LISTEN 0.0.0.0
EOF
  fi
  if [ -e "$BASEDIR/local/upsd.users" ]; then
    cp "$BASEDIR/local/upsd.users" "$BASEDIR/upsd.users"
  else
    cat <<EOF >>"$BASEDIR/upsd.users"
[$API_USER]
        password = $API_PASSWORD
        upsmon $SERVER
EOF
  fi
  if [ -e "$BASEDIR/local/upsmon.conf" ]; then
    cp "$BASEDIR/local/upsmon.conf" "$BASEDIR/upsmon.conf"
  else
    cat <<EOF >>"$BASEDIR/upsmon.conf"
MONITOR $NAME@localhost 1 $API_USER $API_PASSWORD $SERVER
RUN_AS_USER $USER
EOF
  fi
  touch "$BASEDIR/.setup"
fi

chgrp "$GROUP" "$BASEDIR"/*
chmod 640 "$BASEDIR"/*
mkdir -p -m 2750 /dev/shm/nut
chown "$USER:$GROUP" /dev/shm/nut
[ -e /var/run/nut ] || ln -s /dev/shm/nut /var/run
# Issue #15 - change pid warning message from "No such file" to "Ignoring"
echo 0 > /var/run/nut/upsd.pid && chown "$USER:$GROUP" /var/run/nut/upsd.pid
echo 0 > /var/run/upsmon.pid

/usr/sbin/upsdrvctl -u root start
/usr/sbin/upsd -u "$USER"
exec /usr/sbin/upsmon -D
