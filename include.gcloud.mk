#
##
## Gcloud commands
## --------------
#
# https://cloud.google.com/about/locations/
# us-west1: Oregon,  us-west2: LA, us-west3: SLC, us-west4: las vegas
#
SHELL := /usr/bin/env bash
REGION ?= us-west1
ZONE= ?= $(REGION)-b
CLUSTER ?= $(USER)
# project id's must be 6-30 characters
PROJECT_PREFIX ?= net
PROJECTS ?= rich lucas guy
# continaer.googleapis.com - GKE
SERVICES ?= container.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com
DEFAULT_PROJECT ?= netdrones
BILLING ?= Mercuries - Zazmic
# Docker repo name
REPO ?= $$(basename $(PWD))
# note the organization is the same as the Google Workspace primary domain
# https://stackoverflow.com/questions/43255794/edit-google-cloud-organization-name
ORG ?= netdron.es


# https://cloud.google.com/sdk/gcloud/reference/organizations/describe
# https://cloud.google.com/compute/docs/gcloud-compute#default-properties
# you cannot create org from the command line we just check for existance
# projects take defaults from config so run those first
# https://cloud.google.com/blog/products/it-ops/filtering-and-formatting-fun-with
# https://medium.com/@raigonjolly/cheat-sheets-gcloud-bq-gsutil-kubectl-for-google-cloud-associate-certificate-4093b8977a01
# https://cloud.google.com/sdk/gcloud/reference/topic/filters
# https://linuxhandbook.com/shell-using/
# https://cloud.google.com/resource-manager/docs/creating-managing-projects
# project id's must be unique across the google cloud
## init: Gloud init sets the login and your default zones and project
.PHONY: init
init:
	BILLING_ACCOUNT=$$(gcloud beta billing accounts list --format='value(name)' --filter='displayName="$(BILLING)"') && \
	echo "Billing $$BILLING_ACCOUNT" && \
	for proj_base in $(PROJECTS); do \
		project="$(PROJECT_PREFIX)-$$proj_base" && \
		if ! gcloud projects list --format="value(projectId)" | grep -q "^$$project$$"; then \
			echo "creating $$project" ; \
			gcloud projects create "$$project" \
				--organization="$$(gcloud organizations describe $(ORG) --format='value(name)' | cut -d / -f 2)" \
		; fi ; \
		if [[ $$(gcloud beta billing projects describe $$project --format='value(billingEnabled)') =~ False ]]; then \
			gcloud beta billing projects link "$$project" \
				--billing-account="$$BILLING_ACCOUNT" \
		; fi ; \
		for service in $(SERVICES); do \
			gcloud services enable $$service --project="$$project" \
		; done ; \
		if ! gsutil ls "gs://$$proj_base.$(ORG)"; then \
			gsutil mb "gs://$$proj_base.$(ORG)" \
		; fi ; \
	done

#there is always a default but it is unpopulated
#if (( $$(gcloud config configurations list --format='value(name)' | wc -l) < 1)); then \
## login: Create initial buckets
.PHONY: login
login:
	if ! gcloud auth list | grep -q "No credentialed accounts"; then \
		gcloud init && \
		gcloud config set compute/region $(REGION) && \
		gcloud config set core/project $(DEFAULT_PROJECT) && \
		gcloud config set artifacts/location $(REGION) \
	; fi

## config: Get default config
.PHONY: config
config:
	gcloud config configurations list
	gcloud config list
	gcloud config get-value compute/region
	gcloud config get-value compute/zone
	gcloud config get-value core/account
	gcloud config get-value core/project
	gcloud compute regions list
	gcloud compute zones list

## status: Get the currents status of running objects
.PHONY: status
status:
	gcloud container clusters list


# https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster
# https://www.marcolancini.it/2021/blog-gke-autopilot/
## autopilot: Creates a GKE autopilot cluster
.PHONY: autopilot
autopilot:
	if ! gcloud container clusters list --format="value(name)" | grep -q "$(DEFAULT_PROJECT)"; then \
		gcloud container clusters create-auto $(CLUSTER) \
			--region $(REGION) \
			--project $(DEFAULT_PROJECT) \
	; fi
	gcloud container clusters get-credentials $(CLUSTER) \
		--region $(REGION) \
		--project $(DEFAULT_PROJECT)
	kubectl cluster-info
	kubectl get nodes

# https://cloud.google.com/build/docs/quickstart-build
# https://cloud.google.com/sdk/gcloud/reference/topic/filters
# https://medium.com/google-cloud/gcr-io-tips-tricks-d80b3c67cb64
## build: Docker image cloud build to gcr.io or internally to $(REGION)-docker.pkg.dev
.PHONY: build
build:
	if ! gcloud artifacts repositories list --format="value(name)" 2>/dev/null | grep -q "^$(REPO)$$"; then \
		gcloud artifacts repositories create "$(REPO)" --repository-format=docker \
	; fi
	gcloud artifacts repositories list
	PROJECT="$$(gcloud config get-value project)" && \
			gcloud builds submit --tag "$(REGION)-docker.pkg.dev/$$PROJECT/$(REPO)/$(REPO)" && \
			gcloud builds submit -t gcr.io/$$PROJECT/$(REPO) .

# https://www.edureka.co/community/58349/mounting-google-cloud-storage-bucket-gke-pod-persistent-disk
# https://karlstoney.com/2017/03/01/fuse-mount-in-kubernetes/
## fuse: Connect a deployment to Google Cloud Storage via Fuse
.PHONY: fuse
fuse:
	echo TBD
