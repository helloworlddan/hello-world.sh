DATE := $(shell date +%Y-%m-%d)

init:
	bundle install

local:
	bundle exec jekyll serve --watch --port 8080

build:
	bundle exec jekyll build -d ../dist

post:
	git co -B "post/${TITLE}"
	sed -E ``s/1970-01-01/${DATE}/'' "site/_templates/1970-01-01-template.markdown" > "site/_posts/${DATE}-${TITLE}.markdown"
	mkdir -p "site/assets/images/${TITLE}"
	touch "site/assets/images/${TITLE}/asset.png"

clean:
	rm -rf .jekyll-cache

.PHONY: all init local deploy publish clean post

