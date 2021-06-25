#!/bin/sh

#
# ORIGINAL AUTHOR: Remy Leone https://github.com/remyleone/scw-s3-action
#

set -euo pipefail

: "${S3_ACCESS_KEY?S3_ACCESS_KEY environment variable must be set}"
: "${S3_SECRET_KEY?S3_SECRET_KEY environment variable must be set}"
: "${S3_ENDPOINT?S3_ENDPOINT environment variable must be set. Ex: s3.fr-par.scw.cloud}"
: "${BUCKET_NAME?BUCKET_NAME environment variable must be set}"
: "${WEBSITE_CONFIG_PATH?WEBSITE_CONFIG_PATH environment variable must be set. Should be path from root project.}"
: "${BUCKET_POLICY_CONFIG_PATH?BUCKET_POLICY_CONFIG_PATH environment variable must be set. Should be path from root project.}"
: "${SOURCE_DIRECTORY?SOURCE_DIRECTORY environment variable must be set. Should be path from root project of the directory you want to sync with s3 bucket.}"

mkdir -p ~/.aws

touch ~/.aws/config

echo "
[plugins]
endpoint = awscli_plugin_endpoint

[default]
endpoint = ${S3_ENDPOINT}
s3 =
  endpoint_url = https://${S3_ENDPOINT}
  signature_version = s3v4
s3api =
  endpoint_url = https://${S3_ENDPOINT}
" > ~/.aws/config

touch ~/.aws/credentials

echo "[default]
aws_access_key_id = ${S3_ACCESS_KEY}
aws_secret_access_key = ${S3_SECRET_KEY}" > ~/.aws/credentials

# Run and preserve output for consumption by downstream actions
aws s3 mb s3://"${BUCKET_NAME}" >"${GITHUB_WORKSPACE}/aws.output"

if [ $? -eq 0 ]; then
    aws s3api put-bucket-website --bucket "${BUCKET_NAME}" --website-configuration file://"${WEBSITE_CONFIG_PATH}" >"${GITHUB_WORKSPACE}/aws.output"
    aws s3api put-bucket-policy --bucket "${BUCKET_NAME}" --policy file://"${BUCKET_POLICY_CONFIG_PATH}" >"${GITHUB_WORKSPACE}/aws.output"
else
    echo "Bucket already created"
fi

aws s3 sync ./"${SOURCE_DIRECTORY}" s3://"${BUCKET_NAME}" "${SYNC_ARGS}" >"${GITHUB_WORKSPACE}/aws.output"

# Write output to STDOUT
cat "${GITHUB_WORKSPACE}/aws.output"
