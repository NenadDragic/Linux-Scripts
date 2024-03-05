# This script uses the curl command to send a GET request to the Simply.com API for Dynamic DNS (DDNS) updates.
# The API endpoint is "https://api.simply.com/ddns.php".

# The options used with curl are as follows:
# -s: Silent mode. Suppresses the progress meter and other unnecessary output.
# -L: Follow redirects. If the API endpoint returns a redirect response, curl will automatically follow it.
#      This is useful if the API endpoint has moved to a different URL.

# The API requires two parameters to be passed in the URL:
# - apikey: The API key for authentication. In this case, the value is "VEoAX8fMFqaxOkmg".
# - domain: The domain name for which the DDNS update is being performed. In this case, the value is "dragic.com".
# - hostname: The hostname or subdomain to be updated. In this case, the value is "nas".

# The -s and -L options are followed by the URL enclosed in double quotes.
# The response from the API is not stored or processed in this script.

# Note: Make sure to replace the API key, domain, and hostname values with your own before running this script.

# Example usage:
# To update the DDNS for the "nas.dragic.com" subdomain using the API key "VEoAX8fMFqaxOkmg", run the following command:
# curl -s -L "https://api.simply.com/ddns.php?apikey=VEoAX8fMFqaxOkmg&domain=dragic.com&hostname=nas"

# Feel free to modify this script according to your specific requirements.

# End of script.

curl -s -L "https://api.simply.com/ddns.php?apikey=VEoAX8fMFqaxOkmg&domain=dragic.com&hostname=nas" # DDNS.sh - Dynamic DNS Update Script