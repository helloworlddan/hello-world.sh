bucket = 

infrastructure:
	cd infrastructure; sceptre launch-stack stamer page

publish:
	cd site && hugo
	aws s3 sync --recursive ./public/* "$(sceptre --output json describe-stack-outputs stamer page | jq -r '.[] | select(.OutputKey==\"BucketName\").OutputValue')"	

.PHONY: infrastructure
