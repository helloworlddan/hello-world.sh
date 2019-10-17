BUCKET := $(shell sceptre --output json --dir infrastructure list outputs stamer/page | jq -r '.[] | ."stamer/page"[] | select(.OutputKey=="Bucket").OutputValue')

all: infrastructure publish clean

post:
	git co -B "post/${TITLE}"
	cp "site/_templates/1970-01-01-template.markdown" "site/_posts/$(date +%Y)-$(date +%m)-$(date +%d)-${TITLE}.markdown"
	mkdir -p "site/assets/images/${TITLE}"

local:
	nohup sleep 2 && open http://localhost:4000 &
	jekyll serve --watch -s site

infrastructure:
	sceptre --dir infrastructure launch -y stamer/page

publish:
	jekyll build -s site
	cd _site && aws s3 sync . "s3://${BUCKET}"

clean:
	rm -rf _site
	rm -rf .sass-cache
	rm -rf .tweet-cache
	rm -rf nohup.out

.PHONY: all local infrastructure publish clean post

