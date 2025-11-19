#!/bin/bash
#
# Script til at mounte/unmounte CIFS shares (DashCam, Dragic, NetBackup)
# Bruger: sudo ./smb.sh <ShareNavn> <mount|unmount>

# Standardindstillinger, der er ens for alle shares
REMOTE_SERVER="192.168.1.50"
MOUNT_BASE_DIR="/mnt"
LOCAL_UID="1000"  # Din bruger-ID
LOCAL_GID="1000"  # Din gruppe-ID
CIFS_VERSION="3.0" # Kan justeres, hvis nødvendigt

# Første argument: Share Navn (f.eks. DashCam)
SHARE_NAME=$1
# Andet argument: Handling (mount eller unmount)
ACTION=$2

# Tjekker om de nødvendige argumenter er givet
if [ -z "$SHARE_NAME" ] || [ -z "$ACTION" ]; then
    echo "Usage: sudo $0 <ShareNavn> <mount|unmount>"
    echo "Eksempel: sudo $0 DashCam mount"
    echo "Tilgængelige shares: DashCam, Dragic, NetBackup"
    exit 1
fi

# Konfigurationsafhængige variabler (baseret på dit input)
case "$SHARE_NAME" in
    DashCam)
        # Den komplette creds-filsti
        CRED_FILE="/home/nenad/.smbcredentials_DashCam"
        # Ekstra CIFS-indstilling fra din oprindelige fstab (tilføjes til options)
        EXTRA_OPTS="_DashCam"
        ;;
    Dragic)
        CRED_FILE="/home/nenad/.smbcredentials_Dragic"
        EXTRA_OPTS="_Dragic"
        ;;
    NetBackup)
        CRED_FILE="/home/nenad/.smbcredentials_NetBackup"
        EXTRA_OPTS="_NetBackup"
        ;;
    *)
        echo "❌ Fejl: Ugyldigt share-navn '$SHARE_NAME'."
        echo "Tilgængelige shares: DashCam, Dragic, NetBackup"
        exit 1
        ;;
esac

# Dynamisk konstruktion af stier
LOCAL_MOUNT_POINT="${MOUNT_BASE_DIR}/${SHARE_NAME}"
REMOTE_PATH="//${REMOTE_SERVER}/${SHARE_NAME}"


# --- Håndtering af Mount ---
if [ "$ACTION" = "mount" ]; then
    echo "Forsøger at mounte $REMOTE_PATH til $LOCAL_MOUNT_POINT..."

    # Opretter mount-punktet, hvis det ikke eksisterer
    mkdir -p "$LOCAL_MOUNT_POINT"

    # Den komplette mount options streng
    MOUNT_OPTIONS="credentials=${CRED_FILE},${EXTRA_OPTS},uid=${LOCAL_UID},gid=${LOCAL_GID},vers=${CIFS_VERSION}"

    # Udfører mount-kommandoen
    mount -t cifs "$REMOTE_PATH" "$LOCAL_MOUNT_POINT" -o "$MOUNT_OPTIONS"

    if [ $? -eq 0 ]; then
        echo "✅ Succes: ${SHARE_NAME} er nu mountet under ${LOCAL_MOUNT_POINT}."
    else
        echo "❌ Fejl ved mount af ${SHARE_NAME}. Tjek creds-filen og netværksforbindelsen."
    fi

# --- Håndtering af Unmount ---
elif [ "$ACTION" = "unmount" ]; then
    echo "Forsøger at unmount $LOCAL_MOUNT_POINT..."

    # Udfører unmount-kommandoen
    umount "$LOCAL_MOUNT_POINT"

    if [ $? -eq 0 ]; then
        echo "✅ Succes: ${SHARE_NAME} er nu unmountet."
    else
        echo "❌ Fejl ved unmount af ${SHARE_NAME}. Er det mountet?"
    fi

# --- Fejlhåndtering ---
else
    echo "Ugyldig handling: '$ACTION'. Brug venligst 'mount' eller 'unmount'."
    exit 1
fi
