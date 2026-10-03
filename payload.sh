#!/bin/bash

# Title: Phone Number Lookup
# Description: Look up authorized phone numbers using Twilio Lookup.
# Author: Custom
# Version: 1.0
# Category: OSINT
#
# Requires:
#   - curl
#   - jq
#   - Twilio Lookup API credentials
#
# Usage:
#   Launch from Pager Payloads menu.
#
# The payload accepts a phone number through the Pager UI
# and displays the lookup results on-device.

PAYLOAD_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CONFIG="$PAYLOAD_DIR/config.sh"

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

if [ ! -f "$CONFIG" ]; then
    ALERT "Configuration file missing!"
    LOG red "Missing: $CONFIG"
    exit 1
fi

. "$CONFIG"

if [ -z "$TWILIO_API_KEY" ] || [ -z "$TWILIO_API_SECRET" ]; then
    ALERT "Twilio credentials missing!"
    exit 1
fi

# ---------------------------------------------------------
# Dependencies
# ---------------------------------------------------------

if ! command -v curl >/dev/null 2>&1; then
    ALERT "curl is not installed!"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    ALERT "jq is not installed!"
    exit 1
fi

# ---------------------------------------------------------
# Get phone number from Pager UI
# ---------------------------------------------------------

PHONE="$(TEXT_PICKER "Enter phone number" "+15551234567")"

if [ -z "$PHONE" ]; then
    ALERT "No phone number entered."
    exit 0
fi

# Remove common formatting characters.
PHONE="$(printf '%s' "$PHONE" | tr -d ' ()-.')"

# Basic US-number convenience handling.
case "$PHONE" in
    +*)
        ;;
    1*)
        PHONE="+$PHONE"
        ;;
    *)
        PHONE="+1$PHONE"
        ;;
esac

LOG blue "Looking up $PHONE"

# ---------------------------------------------------------
# API request
# ---------------------------------------------------------

SPINNER="$(START_SPINNER "Looking up phone number...")"

ENCODED_PHONE="$(printf '%s' "$PHONE" | sed 's/+/%2B/g')"

RESPONSE="$(
    curl -sS \
        --user "$TWILIO_API_KEY:$TWILIO_API_SECRET" \
        --get \
        "$API_URL/$ENCODED_PHONE" \
        --data-urlencode "Fields=line_type_intelligence"
)"

CURL_STATUS=$?

STOP_SPINNER "$SPINNER"

if [ "$CURL_STATUS" -ne 0 ]; then
    ALERT "Network/API request failed."
    LOG red "curl failed with status $CURL_STATUS"
    exit 1
fi

# ---------------------------------------------------------
# API error handling
# ---------------------------------------------------------

if echo "$RESPONSE" | jq -e '.code' >/dev/null 2>&1; then

    ERROR_MESSAGE="$(
        echo "$RESPONSE" |
        jq -r '.message // "Unknown Twilio error"'
    )"

    ALERT "Lookup failed!"
    LOG red "$ERROR_MESSAGE"

    exit 1
fi

# ---------------------------------------------------------
# Parse results
# ---------------------------------------------------------

VALID="$(
    echo "$RESPONSE" |
    jq -r '.valid // "unknown"'
)"

E164="$(
    echo "$RESPONSE" |
    jq -r '.phone_number // "unknown"'
)"

NATIONAL="$(
    echo "$RESPONSE" |
    jq -r '.national_format // "unknown"'
)"

COUNTRY="$(
    echo "$RESPONSE" |
    jq -r '.country_code // "unknown"'
)"

CALLING_CODE="$(
    echo "$RESPONSE" |
    jq -r '.calling_country_code // "unknown"'
)"

CARRIER="$(
    echo "$RESPONSE" |
    jq -r '.line_type_intelligence.carrier_name // "Unavailable"'
)"

LINE_TYPE="$(
    echo "$RESPONSE" |
    jq -r '.line_type_intelligence.type // "Unavailable"'
)"

MCC="$(
    echo "$RESPONSE" |
    jq -r '.line_type_intelligence.mobile_country_code // "Unavailable"'
)"

MNC="$(
    echo "$RESPONSE" |
    jq -r '.line_type_intelligence.mobile_network_code // "Unavailable"'
)"

# ---------------------------------------------------------
# Log results
# ---------------------------------------------------------

LOG green "Lookup complete"
LOG "Number: $E164"
LOG "Valid: $VALID"
LOG "Country: $COUNTRY"
LOG "Carrier: $CARRIER"
LOG "Line Type: $LINE_TYPE"

# ---------------------------------------------------------
# Display results
# ---------------------------------------------------------

RESULTS="Valid: $VALID
E.164: $E164
National: $NATIONAL
Country: $COUNTRY
Calling Code: +$CALLING_CODE
Carrier: $CARRIER
Line Type: $LINE_TYPE
MCC: $MCC
MNC: $MNC"

ALERT "$RESULTS"

exit 0
