#!/bin/bash

# Install socat if not already installed
sudo apt-get update
sudo apt-get install -y socat

# Start socat to forward port 5601 to OpenSearch dashboard
socat TCP-LISTEN:5601,fork TCP:vpc-opensearch-cluster-ckv7i4qcfrsf5elbt7i2abh23e.us-west-2.es.amazonaws.com:443
