build:
	gcloud builds submit --tag="gcr.io/$$(gcloud config get-value project)/hwsh" container/
	gcloud run deploy --region=europe-west4 --image="gcr.io/$$(gcloud config get-value project)/hwsh" hwsh-blog-service

deploy:
	make -C infrastructure deploy

destroy:
	make -C infrastructure destroy

.PHONY:  deploy destroy build
