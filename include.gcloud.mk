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
DEFAULT_USER ?= rich
MACHINE ?= net-$(DEFAULT_USER)
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
## org-init: Gloud init sets the organziation, its projects and bllling up
.PHONY: org-init
org-init:
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
## init: Initialize for a new user
.PHONY: init
init:
	if ! gcloud auth list | grep -q "No credentialed accounts"; then \
		gcloud init && \
		gcloud config set compute/region $(REGION) && \
		gcloud config set project $(DEFAULT_PROJECT) && \
		gcloud config set artifacts/location $(REGION) \
	; fi

## list: List the current Get default config
# these are long lists of active regions and zones
#gcloud compute regions list
#gcloud compute zones list
.PHONY: list
list:
	gcloud config configurations list
	gcloud config list
	gcloud config get-value compute/region
	gcloud config get-value compute/zone
	gcloud config get-value core/account
	gcloud config get-value core/project
	gcloud compute accelerator-types list
	gcloud compute images list
	gcloud compute machine-types list

## workstation: Create a linux gpu enable station
# https://cloud.google.com/compute/docs/gpus
.PHONY: workstation
workstation:
	gcloud compute instances create ws-$(DEFAULT_USER) \
		--machine-type n1-standard-2
		--accelerator type=nvidia-tesla-k80,count=1 \
		--can-ip-forward \
		--maintenance-policy TERMINATE \
		--restart-on-failure
		--tags "$(DEFAULT_USER)" \
		--image-project ubuntu-os-cloud \
		--image-family ubuntu-2004-lts \
		--boot-disk-size 100

## tf: build terraform using *.tf files in current directory
.PHONY: tf
tf: tf-lint
	terraform plan
	terraform apply


## tf-lint: check if terraform plan is valid
.PHONY: tf-lint
tf-lint:
	terraform show
	terraform fmt
	terraform init
	terraform validate

## terminated: terminate an instance which keeps it from costing money
.PHONY: terminated
terminated: tf-lint
	terraform plan -var="desired_status=TERMINATED"
	terraform apply -var="desired_status=TERMINATED"

## destroy: uninstall all the terraform plans in the current directory
.PHONY: destroy
ARGS :=
ifdef DESTROY_TARGET
	ARGS := -target=$(DESTROY_TARGET)
endif

destroy: tf-lint
ifdef DESTROY_TARGET
	@echo debug: destroy target is $(DESTROY_TARGET)
endif
@echo debug: ARGS is $(ARGS)
	terraform plan -destroy $(ARGS)
	terraform destroy $(ARGS)


## password: reset the windows password this cannnot be run from terraform
.PHONY: password
password:
	gcloud beta compute reset-windows-password $(MACHINE) --project $(DEFAULT_PROJECT)

## ssh: ssh into terraform
.PHONY: ssh
ssh:
	eval ssh "$$(terraform output ip)"

## service: Create a service account
# https://cloud.google.com/sdk/gcloud/reference/auth/activate-service-account
# https://cloud.google.com/iam/docs/creating-managing-service-accounts
			#--role=roles/compute.osLogin 
.PHONY: service
service:
	SERVICE="$(PROJECT_PREFIX)-$(DEFAULT_USER)-service" && \
	echo $$SERVICE && \
	EMAIL="$$SERVICE@$(DEFAULT_PROJECT).iam.gserviceaccount.com" && \
	echo $$EMAIL && \
	if ! gcloud iam service-accounts list --format="value(name)" | grep $$SERVICE; then \
		echo "Create $$SERVICE" && \
		gcloud iam service-accounts create $$SERVICE \
			--description="Service Account for $(DEFAULT_USER)" && \
		gcloud projects add-iam-policy-binding $(DEFAULT_PROJECT) \
			--member="serviceAccount:$$EMAIL" \
			--role=roles/editor \
	; fi && \
	if ! [[ -e $$SERVICE.key.json ]]; then \
		gcloud iam service-accounts keys create $$SERVICE.key.json --iam-account=$$EMAIL \
	; fi 
	#gcloud auth activate-service-account 

## status: Get the currents status of running objects
.PHONY: status
status:
	gcloud container clusters list


# https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster
# https://www.marcolancini.it/2021/blog-gke-autopilot/
## gke: Creates a GKE autopilot cluster
.PHONY: gke
gke:
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
