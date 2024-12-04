#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with sudo or as root."
  echo "Please re-run the script with 'sudo $0'."
  exit 1
fi

# Test if Go is installed
GOBIN=$(which go)
if [ -z "$GOBIN" ]; then
    read -r -p "Go is not installed, do you want to install it automatically? (y/N)" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Go is required to run this script. Install it manually and then rerun this script."
        exit 1
    fi
    wget -q -O /tmp/go.pkg https://dl.google.com/go/go1.23.3.darwin-arm64.pkg
    echo "c619a120cf063ad548061cb6732b9c79d1bb0ba4 /tmp/go.pkg" | sha1sum -c -
    installer -pkg /tmp/go.pkg -target /
fi
GOBIN=/usr/local/go/bin/go
export GOBIN=$GOBIN
export GOPATH=$HOME/go

# Sanity check
if [[ ! -f "$GOBIN" ]]; then
    echo "Go installation failed. Please install Go manually and then rerun this script."
    exit 1
fi

echo "Building the kwkhtmltopdf client"
rm client/go/kwkhtmltopdf_client
"$GOBIN" build -o client/go/kwkhtmltopdf_client client/go/kwkhtmltopdf_client.go
chmod +x client/go/kwkhtmltopdf_client

# Uninstall existing wkhtmltox if exists
if [[ -n $(which uninstall-wkhtmltox) ]]; then
    read -r -p "wkhtmltox is already installed, do you want to uninstall it? (y/N)" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "This script requires wkhtmltox to be uninstalled. Please uninstall it and then rerun this script."
            exit 1
    fi
    uninstall-wkhtmltox
fi

# Install the client in place of wkhtmltopdf
echo "Copying kwkhtmltopdf to /usr/local/bin/wkhtmltopdf"
cp client/go/kwkhtmltopdf_client /usr/local/bin/wkhtmltopdf
