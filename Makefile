post:
	cd site && hugo new "posts/${title}.md"
	mkdir -p "site/static/images/${title}"

local:
	hugo server -D -s site

infrastructure:
	cd infrastructure; sceptre launch-stack stamer page

publish:
	hugo -s site
	cd site/public && aws s3 sync . s3://hello-world-stamer-page-bucket-mzwqo0v2xt1t			

clean:
	rm -rf site/public

.PHONY: infrastructure
