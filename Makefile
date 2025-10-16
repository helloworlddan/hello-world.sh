all: init build deploy

init:
	gcloud services enable {firestore,run,artifactregistry,cloudbuild}.googleapis.com
	gcloud artifacts repositories create gcr.io \
		--repository-format docker \
		--location us
	gcloud firestore databases create \
		--location "$$(gcloud config get-value run/region)"
	gcloud iam service-accounts create hwshsa
	gcloud projects add-iam-policy-binding $$(gcloud config get-value project) \
		--member "serviceAccount:hwshsa@$$(gcloud config get-value project).iam.gserviceaccount.com" \
		--role "roles/datastore.user"

build:
	gcloud builds submit --tag="gcr.io/$$(gcloud config get-value project)/image" .

deploy:
	gcloud run deploy hwsh \
		--image "gcr.io/$$(gcloud config get-value project)/image" \
		--region "$$(gcloud config get-value run/region)" \
		--allow-unauthenticated \
		--service-account "hwshsa@$$(gcloud config get-value project).iam.gserviceaccount.com"

update: build deploy

local:
	go run main.go

.PHONY:  all init build deploy update local
