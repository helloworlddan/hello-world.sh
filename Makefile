init:
	make -C site init

local:
	make -C site local

build:
	make -C site build
	cp static/* dist/

post:
	make -C site post

publish: build
	cp -r ../dist ../container/site
	gcloud builds submit --tag="gcr.io/$$(shell gcloud config get-value project)/hwsh" container/
	gcloud run deploy --platform=managed --region=europe-west4 --image="gcr.io/$$(shell gcloud config get-value project)/hwsh" hwsh-blog-service

deploy:
	make -C infrastructure init deploy

clean:
	make -C site clean
	make -C infrastructure clean
	rm -rf dist

.PHONY: init local build post publish deploy clean

