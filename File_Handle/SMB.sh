#!/bin/bash
#
# Script til at mounte/unmounte CIFS shares (DashCam, Dragic, NetBackup)
# Bruger: sudo ./smb.sh <ShareNavn> <mount|umount>

# Standardindstillinger
REMOTE_SERVER="192.168.1.50"
MOUNT_BASE_DIR="/mnt"
LOCAL_UID="1000"
LOCAL_GID="1000"
CIFS_VERSION="3.0"

# Hent argumenter
SHARE_NAME=$1
# Konverter ACTION til små bogstaver (virker i Bash 4.0+)
ACTION=${2,,}

# Tjekker om de nødvendige argumenter er givet
if [ -z "$SHARE_NAME" ] || [ -z "$ACTION" ]; then
    echo "Usage: sudo $0 <ShareNavn> <mount|umount>"
    echo "Eksempel: sudo $0 DashCam mount"
    echo "Tilgængelige shares: DashCam, Dragic, NetBackup"
    exit 1
fi

# Konfigurationsafhængige variabler
# Vi bruger også her lowercase tjek for share-navnet for at gøre det mere brugervenligt
case "${SHARE_NAME,,}" in
    dashcam)
        REAL_NAME="DashCam"
        CRED_FILE="/home/nenad/.smbcredentials_DashCam"
        EXTRA_OPTS=""
        ;;
    dragic)
        REAL_NAME="Dragic"
        CRED_FILE="/home/nenad/.smbcredentials_Dragic"
        EXTRA_OPTS=""
        ;;
    netbackup)
        REAL_NAME="NetBackup"
        CRED_FILE="/home/nenad/.smbcredentials_NetBackup"
        EXTRA_OPTS=""
        ;;
    *)
        echo "❌ Fejl: Ugyldigt share-navn '$SHARE_NAME'."
        echo "Tilgængelige shares: DashCam, Dragic, NetBackup"
        exit 1
        ;;
esac

# Dynamisk konstruktion af stier (bruger REAL_NAME for at matche mappenavne præcist)
LOCAL_MOUNT_POINT="${MOUNT_BASE_DIR}/${REAL_NAME}"
REMOTE_PATH="//${REMOTE_SERVER}/${REAL_NAME}"

# --- Håndtering af Mount ---
if [ "$ACTION" = "mount" ]; then
    echo "Forsøger at mounte $REMOTE_PATH til $LOCAL_MOUNT_POINT..."

    mkdir -p "$LOCAL_MOUNT_POINT"
    MOUNT_OPTIONS="credentials=${CRED_FILE},${EXTRA_OPTS},uid=${LOCAL_UID},gid=${LOCAL_GID},vers=${CIFS_VERSION}"

    mount -t cifs "$REMOTE_PATH" "$LOCAL_MOUNT_POINT" -o "$MOUNT_OPTIONS"

    if [ $? -eq 0 ]; then
        echo "✅ Succes: ${REAL_NAME} er nu mountet under ${LOCAL_MOUNT_POINT}."
    else
        echo "❌ Fejl ved mount af ${REAL_NAME}. Tjek creds-filen."
    fi

# --- Håndtering af Unmount ---
elif [ "$ACTION" = "umount" ] || [ "$ACTION" = "unmount" ]; then
    echo "Forsøger at umount $LOCAL_MOUNT_POINT..."

    umount "$LOCAL_MOUNT_POINT"

    if [ $? -eq 0 ]; then
        echo "✅ Succes: ${REAL_NAME} er nu umountet."
    else
        echo "❌ Fejl ved umount af ${REAL_NAME}. Er det mountet?"
    fi

# --- Fejlhåndtering ---
else
    echo "Ugyldig handling: '$2'. Brug venligst 'mount' eller 'umount'."
    exit 1
fi
