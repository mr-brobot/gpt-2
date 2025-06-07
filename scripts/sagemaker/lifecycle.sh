#!/bin/bash
set -eux
sudo -u ec2-user -i <<'EOF'
pip install --quiet --upgrade "sagemaker-ssh-helper"
EOF
