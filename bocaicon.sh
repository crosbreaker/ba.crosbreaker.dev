#!/bin/bash
if [ -e "/usr/share/icons/hicolor/48x48/apps/google-chrome.png" ]; then
  rm -f /usr/share/icons/hicolor/48x48/apps/google-chrome.png
  curl -L https://cdn.crosbreaker.dev/boca/icon.png -O /usr/share/icons/hicolor/48x48/apps/google-chrome.png
  echo "the icon should be changed."
  exit 0
else
  echo "Could not locate the chrome icon, exiting."
  exit 1
fi
