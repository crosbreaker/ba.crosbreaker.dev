#!/bin/bash
echo --enterprise-enable-state-determination=never >/tmp/chrome_dev.conf
mount --bind /tmp/chrome_dev.conf /etc/chrome_dev.conf
initctl restart ui
