board=$1
recoveryver=$2
fail() {
    printf "%b\n" "$1" >&2
    printf "error occurred\n" >&2
    exit 1
}
findimage(){ # Taken from murkmod
    echo "Attempting to find recovery image from https://github.com/MercuryWorkshop/chromeos-releases-data data..."
    local mercury_data_url="https://raw.githubusercontent.com/MercuryWorkshop/chromeos-releases-data/refs/heads/main/data.json"
    local mercury_url=$(curl -ks "$mercury_data_url" | jq -r --arg board "$board" --arg version "$recoveryver" '
      .[$board].images
      | map(select(
          .channel == "stable-channel" and
          (.chrome_version | type) == "string" and
          (.chrome_version | startswith($version + "."))
        ))
      | sort_by(.platform_version)
      | .[0].url
    ')

    if [ -n "$mercury_url" ] && [ "$mercury_url" != "null" ]; then
        echo "Found a match!"
        FINAL_URL="$mercury_url"
        MATCH_FOUND=1
        echo "$mercury_url"
    fi
}
findimage
curl --progress-bar -k "$FINAL_URL" -o recovery.zip || fail "Failed to download recovery image"
 
