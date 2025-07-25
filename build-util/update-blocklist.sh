#!/bin/sh

#  update-blocklist.sh
#  AnyoneBrowser
#
#  Created by Benjamin Erhart on 24.07.25.
#  Copyright © 2025 Anyone. All rights reserved.

load() {
    curl --remote-name --progress-bar --location $1
}

BLOCKLIST_NAME=light-onlydomains.txt

cd Resources

# Test if file is older then 1 day.
OLD="$(find $BLOCKLIST_NAME -mmin +1440 2>/dev/null)"

# Only download, if file is not existing or older than 1 day.
if [ ! -f "$BLOCKLIST_NAME" -o ! -z "$OLD" ]; then
	load "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/$BLOCKLIST_NAME"
fi
