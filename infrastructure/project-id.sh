#!/bin/sh

gcloud config list core/project --format json | jq -r '.core'