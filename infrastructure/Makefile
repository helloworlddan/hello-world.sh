init:
	gsutil mb gs://hwsh-blog-admin || exit 0
	terraform init

deploy:
	terraform apply

clean:
	rm .rf .terraform
	rm .rf .terraform.lock.hcl

.PHONY: init deploy

