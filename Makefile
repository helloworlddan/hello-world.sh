BUCKET := $(shell /usr/local/bin/sceptre --output json --dir infrastructure describe-stack-outputs stamer page | jq -r ".[] | select(.OutputKey==\"Bucket\").OutputValue")

all: infrastructure publish

local:
	hugo server -D -s site

infrastructure:
	cd infrastructure; sceptre launch-stack stamer page

publish:
	hugo -s site
	cd site/public && aws s3 sync . "s3://${BUCKET}"

clean:
	rm -rf site/public
	aws s3 rm --recursive "s3://${BUCKET}/"

.PHONY: all local infrastructure publish clean
