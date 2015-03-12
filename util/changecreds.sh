#!/bin/sh

usage() {
cat << EOF

Usage: 

  $0 [-u [username]] [-p]

  Options:
    -u <username> : Optionally specify the new username for this mFi.  
    -p : Prompt for a new password.

EOF
}

die() {
  echo
  echo "$1, so giving up.  Sorry."
  echo
  exit 2
}

CONFIG_LOCATION=/tmp/system.cfg

PSET=false

while getopts "u:p" OPTION ; do
  case "$OPTION" in
    h) usage
       exit 1 ;;
    u) NEW_USER="$OPTARG";;
    p) PSET=true ;;
    ?) usage
       exit 1 ;;
  esac
done

if [ -z "$NEW_USER" ] && ! $PSET ; then
  usage
  exit 1
fi

USER=`grep -v nobody /etc/passwd | sed -e 's/:.*//' | head -1`

if [ -z "$USER" ] ; then
  die "Could not identify the existing user"
fi


if [ -n "$NEW_USER" ] ; then

  if [ "$USER" != "$NEW_USER" ] ; then
    sed -ie "s/^$USER:/$NEW_USER:/" /etc/passwd || die "Error changing username"
    echo "Username successfully updated."
  else
    echo
    echo "Looks like you specified your current username ($USER)."
    echo "This won't harm anything, but it's not necessary."
    echo
  fi

  USER="$NEW_USER"
fi

if $PSET ; then
  passwd $USER || die "Busybox didn't like your password"
fi

HASHED_PASSWORD=`grep $USER /etc/passwd | awk -F: '{print $2}'`

if [ -z "$HASHED_PASSWORD" ] ; then
  die "Could not identify the password hash"
fi

echo
echo "Nothing has been committed past a reboot yet."
echo

{
  cat "$CONFIG_LOCATION" | grep -ve 'users\.1\.\(name\|password\)'
  echo users.1.name=$USER
  echo users.1.password=$HASHED_PASSWORD
} | sort > "$CONFIG_LOCATION".new

echo "Saving config"
cfgmtd -f "$CONFIG_LOCATION".new -w || die "Error saving config"

echo
echo "Now it's persistent.  Feel free to reboot now, but you don't have to."
echo
