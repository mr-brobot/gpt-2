#!/bin/bash
set -eux

aws ssm update-service-setting \
  --setting-id arn:aws:ssm:us-west-2:898546127587:servicesetting/ssm/managed-instance/activation-tier \
  --setting-value advanced
