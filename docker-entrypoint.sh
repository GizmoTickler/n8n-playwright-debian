#!/bin/sh
set -e

# Custom certificate support
if [ -d /opt/custom-certificates ]; then
	# Check if directory contains any certificate files
	if ls /opt/custom-certificates/*.pem /opt/custom-certificates/*.crt 2>/dev/null | head -1 >/dev/null; then
		echo "📜 Loading custom certificates from /opt/custom-certificates..."
		export NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--use-openssl-ca"
		export SSL_CERT_DIR=/opt/custom-certificates
		if command -v c_rehash >/dev/null 2>&1; then
			c_rehash /opt/custom-certificates 2>/dev/null || echo "⚠️ c_rehash completed with warnings"
		fi
		echo "✅ Custom certificates configured"
	fi
fi

# Execute n8n with any provided arguments
if [ -n "$1" ]; then
	exec n8n "$@"
else
	exec n8n
fi
