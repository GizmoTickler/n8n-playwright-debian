#!/bin/sh

# Custom certificate support
if [ -d /opt/custom-certificates ]; then
	export NODE_OPTIONS=--use-openssl-ca
	export SSL_CERT_DIR=/opt/custom-certificates
	c_rehash /opt/custom-certificates
fi

# Execute n8n with any provided arguments
if [ -n "$1" ]; then
	exec n8n "$@"
else
	exec n8n
fi
