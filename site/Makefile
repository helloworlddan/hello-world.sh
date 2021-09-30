DATE := $(shell date +%Y-%m-%d)

init:
	bundle install

local: init
	bundle exec jekyll serve --watch --port 8080

build: init
	bundle exec jekyll build -d ../dist
	rm ../dist/Makefile

post:
	git co -B "post/${TITLE}"
	sed -E ``s/1970-01-01/${DATE}/'' "_templates/1970-01-01-template.markdown" > "_posts/${DATE}-${TITLE}.markdown"
	mkdir -p "assets/images/${TITLE}"
	touch "assets/images/${TITLE}/asset.png"

clean:
	rm -rf .jekyll-cache
	rm -rf .tweet-cache

.PHONY: all init local deploy publish clean post

