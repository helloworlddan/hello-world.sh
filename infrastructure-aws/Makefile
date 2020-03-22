infrastructure:
	sceptre launch -y stamer/page

publish:
	BUCKET := $(shell sceptre --output json --dir infrastructure list outputs stamer/page | jq -r '.[] | ."stamer/page"[] | select(.OutputKey=="Bucket").OutputValue')
	jekyll build -s site
	cd _site && aws s3 sync . "s3://${BUCKET}"