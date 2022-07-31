local:
	make -C site local

build:
	make -C site build

post:
	make -C site post

publish: build
	cp -r dist container/site
	gcloud builds submit --tag="gcr.io/$$(gcloud config get-value project)/hwsh" container/
	gcloud run deploy --region=europe-west4 --image="gcr.io/$$(gcloud config get-value project)/hwsh" hwsh-blog-service

deploy:
	make -C infrastructure deploy

destroy:
	make -C infrastructure destroy

clean:
	make -C site clean
	make -C infrastructure clean
	rm -rf dist
	rm -rf container/site

.PHONY: init local build post publish deploy clean destroy

