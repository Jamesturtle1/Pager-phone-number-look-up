# Pager-phone-number-look-up

# Phone Number Lookup

Interactive WiFi Pineapple Pager payload for authorized phone-number
lookup using the Twilio Lookup API.

## Features

- Pager touchscreen/UI text input
- Phone number normalization
- Twilio Lookup v2
- Number validation
- E.164 formatting
- National formatting
- Country code
- Calling country code
- Carrier
- Line type
- Mobile country code
- Mobile network code

## Requirements

- WiFi Pineapple Pager
- curl
- jq
- Twilio Lookup account
- Twilio API credentials
- Line Type Intelligence enabled if carrier/line-type information
  is desired

## Installation

Copy the directory into:

/mmc/root/payloads/user/osint/phone_lookup/

Then make the payload executable:

chmod +x payload.sh
chmod 600 config.sh

Edit config.sh and enter your own Twilio credentials.

## Usage

Open:

Payloads > OSINT > Phone Number Lookup

Enter a phone number when prompted.

Use only with numbers you are authorized to investigate.
