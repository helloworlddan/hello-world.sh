DATE := $(shell date +%Y-%m-%d)

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

infrastructure-aws:
	make -C infrastructure-aws

infrastructure-gcp:
	make -C infrastructure-gcp

publish-container:
	$(eval PROJECT := $(shell sh infrastructure-gcp-cloudrun/project-id.sh | jq -r '.project'))
	bundle exec jekyll build -s site
	cp -r _site container/site
	docker build -t "gcr.io/${PROJECT}/hwsh" container/
	docker push "gcr.io/${PROJECT}/hwsh"
	gcloud beta run deploy --platform=managed --region=europe-west4 --image="gcr.io/${PROJECT}/hwsh" --allow-unauthenticated hwsh-blog-service

publish-aws:
	$(eval BUCKET := $(shell sceptre --output json --dir infrastructure list outputs stamer/page | jq -r '.[] | ."stamer/page"[] | select(.OutputKey=="Bucket").OutputValue'))
	bundle exec jekyll build -s site
	cd _site && aws s3 sync . "s3://${BUCKET}"

publish-gcp:
	$(eval BUCKET := $(shell cd infrastructure && tf output -json | jq -r '.bucket.value'))
	bundle exec jekyll build -s site
	cd _site && gsutil -m rsync -r -d . "gs://$(BUCKET)"

clean:
	rm -rf _site
	rm -rf .sass-cache
	rm -rf .tweet-cache
	rm -rf container/site
	rm -rf nohup.out

.PHONY: all init local infrastructure-gcp infrastructure-aws publish clean post

