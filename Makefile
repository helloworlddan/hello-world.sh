DATE := $(shell date +%Y-%m-%d)

init:
	bundle install --deployment

post:
	git co -B "post/${TITLE}"
	sed -E ``s/1970-01-01/${DATE}/'' "site/_templates/1970-01-01-template.markdown" > "site/_posts/${DATE}-${TITLE}.markdown"
	mkdir -p "site/assets/images/${TITLE}"
	touch "site/assets/images/${TITLE}/asset.png"

local:
	bundle exec jekyll serve --watch -s site

build:
	bundle exec jekyll build -s site

infrastructure-s3:
	make -C infrastructure/aws-s3 infrastructure

infrastructure-gcs:
	make -C infrastructure/gcp-gcs infrastructure

infrastructure-cloudrun:
	make -C infrastructure/gcp-cloudrun infrastructure

publish-cloudrun:
	$(eval PROJECT := $(shell sh infrastructure/gcp-cloudrun/project-id.sh | jq -r '.project'))
	bundle exec jekyll build -s site
	cp -r _site container/site
	gcloud builds submit --tag="gcr.io/${PROJECT}/hwsh" container/
	gcloud beta run deploy --platform=managed --region=europe-west4 --image="gcr.io/${PROJECT}/hwsh" --allow-unauthenticated hwsh-blog-service

publish-s3:
	BUCKET := $(shell sceptre --output json --dir infrastructure list outputs stamer/page | jq -r '.[] | ."stamer/page"[] | select(.OutputKey=="Bucket").OutputValue')
	jekyll build -s site
	cd _site && aws s3 sync . "s3://${BUCKET}"

publish-gcs:
	$(eval BUCKET := $(shell cd infrastructure && tf output -json | jq -r '.bucket.value'))
	bundle exec jekyll build -s site
	cd _site && gsutil -m rsync -r -d . "gs://$(BUCKET)"

clean:
	rm -rf infrastructure/*/.terraform
	rm -rf _site
	rm -rf vendor
	rm -rf .bundle
	rm -rf .sass-cache
	rm -rf .tweet-cache
	rm -rf container/site
	rm -rf nohup.out

.PHONY: all init local infrastructure-gcp infrastructure-aws infrastructure-cloudrun publish-cloudrun publish-gcs publis-s3 clean post

