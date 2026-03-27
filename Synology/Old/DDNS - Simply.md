# DDNS - Simply

Sends a DDNS update request to the Simply.com API to update the `nas.dragic.com` subdomain with the current IP.

## Command

```bash
curl -s -L "https://api.simply.com/ddns.php?apikey=<apikey>&domain=dragic.com&hostname=nas"
```

## Parameters

| Parameter | Value | Description |
| --------- | ----- | ----------- |
| `apikey` | *(see script)* | API key for authentication |
| `domain` | `dragic.com` | Domain to update |
| `hostname` | `nas` | Subdomain to update (`nas.dragic.com`) |

## Options

| Option | Description |
| ------ | ----------- |
| `-s` | Silent mode — suppresses progress output |
| `-L` | Follow redirects |

## Usage

```bash
bash "DDNS - Simply.sh"
```

> **Note:** The API key is stored in plaintext in the script. Avoid committing this to a public repository.
