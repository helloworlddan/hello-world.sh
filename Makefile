BUCKET := $(shell /usr/local/bin/sceptre --output json --dir infrastructure describe-stack-outputs stamer page | jq -r ".[] | select(.OutputKey==\"Bucket\").OutputValue")

all: infrastructure publish

post:
	touch "site/_posts/2000-01-01-${title}.markdown"
	mkdir -p "site/assets/images/${title}"

local:
	jekyll serve --watch -s site

infrastructure:
	sceptre --dir infrastructure launch-stack stamer page

publish:
	jekyll build -s site
	cd _site && aws s3 sync . "s3://${BUCKET}"

clean:
	rm -rf _site
	rm -rf .sass-cache
	rm -rf .tweet-cache

.PHONY: all local infrastructure publish clean post
