#!/bin/bash
dir=$(mktemp -d)
cd "$dir"
futility gbb -g --flash -r recoverykey.bin
futility show recoverykey.bin
rm recovery_key.bin
