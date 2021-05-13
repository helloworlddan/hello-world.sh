DATE := $(shell date +%Y-%m-%d)

init:
	bundle install

post:
	git co -B "post/${TITLE}"
	sed -E ``s/1970-01-01/${DATE}/'' "site/_templates/1970-01-01-template.markdown" > "site/_posts/${DATE}-${TITLE}.markdown"
	mkdir -p "site/assets/images/${TITLE}"
	touch "site/assets/images/${TITLE}/asset.png"

local:
	bundle exec jekyll serve --watch -s site --port 5000

build:
	bundle exec jekyll build -s site
	cp static/* _site/

infrastructure-cloudrun:
	make -C infrastructure/gcp-cloudrun infrastructure

publish-cloudrun:
	$(eval PROJECT := $(shell sh infrastructure/gcp-cloudrun/project-id.sh | jq -r '.project'))
	bundle exec jekyll build -s site
	cp static/* _site/
	cp -r _site container/site
	gcloud builds submit --tag="gcr.io/${PROJECT}/hwsh" container/
	gcloud beta run deploy --platform=managed --region=europe-west4 --image="gcr.io/${PROJECT}/hwsh" --allow-unauthenticated hwsh-blog-service

clean:
	rm -rf infrastructure/*/.terraform
	rm -rf container/go.sum
	rm -rf _site
	rm -rf vendor
	rm -rf .bundle
	rm -rf .sass-cache
	rm -rf .tweet-cache
	rm -rf site/.jekyll-cache
	rm -rf container/site
	rm -rf nohup.out

.PHONY: all init local infrastructure-cloudrun publish-cloudrun clean post

