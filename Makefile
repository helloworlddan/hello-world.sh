DATE := $(shell date +%Y-%m-%d)

all: init infrastructure publish clean

init:
	bundle install --deployment

post:
	git co -B "post/${TITLE}"
	sed -E ``s/1970-01-01/${DATE}/'' "site/_templates/1970-01-01-template.markdown" > "site/_posts/${DATE}-${TITLE}.markdown"
	mkdir -p "site/assets/images/${TITLE}"
	touch "site/assets/images/${TITLE}/asset.png"

local:
	nohup sleep 2 && open http://localhost:4000 &
	bundle exec jekyll serve --watch -s site

infrastructure:
	cd infrastructure; tf init
	cd infrastructure; tf apply

publish:
	$(eval BUCKET := $(shell cd infrastructure && tf output -json | jq -r '.bucket.value'))
	bundle exec jekyll build -s site
	cd _site && gsutil -m rsync -r -d . "gs://$(BUCKET)"

clean:
	rm -rf _site
	rm -rf .sass-cache
	rm -rf .tweet-cache
	rm -rf nohup.out

.PHONY: all init local infrastructure publish clean post

