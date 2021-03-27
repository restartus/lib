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
PROJECTS ?= netdrones net-rich net-lucas net-guy
# continaer.googleapis.com - GKE
SERVICES ?= container.googleapis.com
DEFAULT_PROJECT ?= netdrones
BILLING ?= Mercuries - Zazmic
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
## init: Gloud init sets the login and your default zones and project
# https://linuxhandbook.com/shell-using/
.PHONY: projects
projects:
	echo $$0
	for project in $(PROJECTS); do \
		if ! gcloud projects list --format="value(projectId)" | grep -q "^$$project$$"; then \
			gcloud projects create "$$project" \
				--organization="$$(gcloud organizations describe $(ORG) --format='value(name)' | cut -d / -f 2)" \
		; fi ; \
	; done
.PHONY: billing
billing:
		if [[ $$(gcloud beta billing projects describe $$project --format='value(billingEnabled)') =~ False ]]; then \
			gcloud billing projects link $$project \
				--billing="$$(gcloud beta billing accounts list --format='value(name)' --filter='displayName="$(BILLING)"')" \
		; fi

.PHONY: init
init:

	if (( $$(gcloud config configurations list --format='value(name)' | wc -l) < 1)); then \
		gcloud init && \
		gcloud config set compute/region=$(REGION) && \
		gcloud config set core/project=$(DEFAULT_PROJECT) \
	; fi
	for service in $(SERVICES); do\
		gcloud services enable $$service \
	; done
	gcloud auth configure-docker

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
