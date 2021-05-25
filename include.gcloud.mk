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
SERVICES ?= container.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com billingbudgets.googleapis.com

# defaults for terraform
DEFAULT_USER ?= $(USER)
DEFAULT_PROJECT ?= net-$(DEFAULT_USER)

# used for gcloud creationg
MACHINE ?= net-$(DEFAULT_USER)
ORG_DOMAIN ?= netdron.es

# Docker repo name
REPO ?= $$(basename $(PWD))

# Mercuries - Zazmic is full name but = does not match it
BILLING ?= Mercuries*
BILLING_ACCOUNT ?= $$(gcloud beta billing accounts list --format="value(name)" --filter=displayName:"$(BILLING)")

BUDGET_NAME ?= Budget by Make
BUDGET_AMOUNT ?= 2000USD

# TF_VARS are passed from Makefile and include things like --project=net-rich
# for instance
TF_VARS ?=

# number of instances
COUNT ?= 1

# note the organization is the same as the Google Workspace primary domain
# https://stackoverflow.com/questions/43255794/edit-google-cloud-organization-name
ORG ?= netdron.es

## dns: create google cloud DNS
# https://serverascode.com/2018/01/14/gcloud-dns-setup.html
.PHONY: dns
dns:
	if ! gcloud services list --filter=name:dns.googleapis.com; then \
		gcloud services enable dns.googleapis.com \
	; fi

#there is always a default but it is unpopulated
#if (( $$(gcloud config configurations list --format='value(name)' | wc -l) < 1)); then \
## user: Initialize for a new user
.PHONY: user
user: key
	if gcloud auth list | grep -q "No credentialed accounts"; then \
		gcloud init && \
		gcloud config set compute/region $(REGION) && \
		gcloud config set project $(DEFAULT_PROJECT) && \
		gcloud config set artifacts/location $(REGION) \
		gcloud auth login
	; fi


## key: make a key for gcloud and add it
key:
	KEY_FILE=$(USER)@$(ORG)-cloud.google.com.id_ed25519 && \
	KEY_PATH="$$HOME/.ssh/$$KEY_FILE" && \
	if [[ ! -e $$KEY_PATH ]]; then \
		ssh-keygen -q -o -a 256 -t ed25519 -f "$$KEY_PATH" -C "$$KEY_FILE" && \
		ssh-keygen -q -l -f "$$KEY_PATH" > "$$KEY_PATH.fingerprint" \
	; fi


## org: create project, billing, budget, service
.PHONY: org
org: project billing budget bucket service

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
#BILLING_ACCOUNT=$$(gcloud beta billing accounts list --format='value(name)' --filter='displayName="$(BILLING)"') && \
## service: make services for each project
.PHONY: service
service: project
	for proj_base in $(PROJECTS); do \
		project="$(PROJECT_PREFIX)-$$proj_base" && \
		for service in $(SERVICES); do \
			gcloud services enable $$service --project="$$project" \
		; done ; \
	done

## project: Create Gcloud project
.PHONY: project
project:
	echo $(PROJECTS) | xargs -n 1 \
		bash -c 'project="$(PROJECT_PREFIX)-$$0" && \
			if ! gcloud projects list --format="value(projectId)" | grep -q "^$$project$$"; then \
				echo "creating $$project" ; \
				gcloud projects create "$$project" \
					--organization="$$(gcloud organizations describe $(ORG) --format=\"value(name)\" | cut -d / -f 2)" \
			; fi'

## bucket: make buckets for the whole organization
# note https://en.wikipedia.org/wiki/Xargs#-I_option:_single_argument
# Uses the trick that bash -c has arguments after it that xargs fills in
# do not create like this
#echo $(PROJECTS) | xargs -n 1 \
	#bash -c 'BUCKET=gs://$(ORG)/user/$$0 && \
	#gsutil ls "$$BUCKET" || gsutil mb "$$BUCKET"'
.PHONY: bucket
bucket: billing
	BUCKET="gs://$(ORG_DOMAIN)" && if ! gsutil ls "$$BUCKET" &>/dev/null; then gsutil mb "$$BUCKET"; fi

## billing: create billing links
.PHONY: billing
billing: project
	echo "Billing $(BILLING_ACCOUNT)" && \
	echo $(PROJECTS) | xargs -n 1 \
		bash -c 'project="$(PROJECT_PREFIX)-$$0" && \
			if [[ $$(gcloud beta billing projects describe $$project --format="value(billingEnabled)") =~ False ]]; then \
				echo "creating $$project billing" && \
				gcloud beta billing projects link "$$project" \
					--billing-account=$(BILLING_ACCOUNT) \
			; fi'

# https://cloud.google.com/sdk/gcloud/reference/billing/budgets/create?hl=nl
## budget: set a budget for the project if not already set
# note that the percent is not as a percentage but a fraction
# which is different than the documentation
.PHONY: budget
budget: billing
	if (($$(gcloud billing budgets list \
			--billing-account=$(BILLING_ACCOUNT) \
			--format="value(name)" \
			--filter=displayName:"$(BUDGET_NAME)" | \
			wc -l) < 1 \
	)); then \
		gcloud billing budgets create \
			--billing-account=$(BILLING_ACCOUNT) \
			--display-name="$(BUDGET_NAME)" \
			--budget-amount=$(BUDGET_AMOUNT) \
			--threshold-rule=percent=0.50 \
			--threshold-rule=percent=0.75 \
			--threshold-rule=percent=1 \
	; fi

## delete a budget

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
	gcloud beta billing account list
	gcloud compute accelerator-types list
	for proj_base in $(PROJECTS); do \
		project="$(PROJECT_PREFIX)-$$proj_base" && \
		gcloud beta compute machine-images list --project="$$project"; \
	done

## list-standard: standard types
.PHONY: list-standard
list-standard:
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

## copy: you cannot just copy an image you have to start an instance and then create
# https://stackoverflow.com/questions/63440886/how-to-export-an-image-machine-to-another-gcp-account
MI_PROJECT_SOURCE ?= airy-ceremony-300719
MI_PROJECT_DEST ?= netdrones
MACHINE_IMAGE ?= netdrones-ws-3
# netdrones default service account
# https://stackoverflow.com/questions/34543829/jq-cannot-index-array-with-string
# https://stedolan.github.io/jq/manual/v1.5/#ConditionalsandComparisonso
# https://garthkerr.com/search-json-array-jq/
# https://stackoverflow.com/questions/47006062/how-do-i-list-the-roles-associated-with-a-gcp-service-account
# we look for the account with "compute" in its name assuming it has gcloud
# compute rights but there is an easier way (see below)
	#SERVICE_ACCOUNT=$$(gcloud projects get-iam-policy $(MI_PROJECT_SOURCE) --format=json | \
	#    jq -r '.bindings[] |  select(.role == "roles/editor") | .members[] | select(test("compute"))' | \
	#    cut -d : -f 2) && \
# https://stackoverflow.com/questions/47006062/how-do-i-list-the-roles-associated-with-a-gcp-service-account
# https://cloud.google.com/compute/docs/machine-images/create-machine-images
# instead of searching this way, look directly into the machine image policy
		#if (( $$(gcloud projects get-iam-policy $(MI_PROJECT_SOURCE) --format json | \
		#    jq 'select(.bindings[].members == "serviceAccount:$$DEST_SERVICE_ACCOUNT")' | wc -l ) < 1 )); then \
		#
# https://cloud.google.com/iam/docs/creating-managing-service-accounts
.PHONY: copy
copy:
	@echo "allow $(MI_PROJECT_DEST) image access to project $(MI_PROJECT_SOURCE)s $(MACHINE_IMAGE)"
	if (( $$(gcloud beta compute machine-images list \
			--project=$(MI_PROJECT_DEST) \
			--filter="name=$(MACHINE_IMAGE)" 2>/dev/null | wc -l) <= 1 )); then \
		DEST_SERVICE_ACCOUNT="$$(gcloud iam service-accounts list \
			--project='$(MI_PROJECT_DEST)' \
			--format='value(email)' | grep compute)" && \
		echo "found $$DEST_SERVICE_ACCOUNT" && \
		if (( $$(gcloud beta compute machine-images get-iam-policy \
				$(MACHINE_IMAGE) \
				--project=$(MI_PROJECT_SOURCE) \
			    --filter=bindings.role=roles/compute.admin \
			   	--filter=bindings.members:$$DEST_SERVICE_ACCOUNT \
				--format="value(bindings.members[0])" | wc -l ) < 1)); then \
					echo "adding $$DEST_SERVICE_ACCOUNT to $(MACHINE_IMAGE)" && \
					gcloud beta compute machine-images add-iam-policy-binding  \
						"$(MACHINE_IMAGE)" \
						--project="$(MI_PROJECT_SOURCE)" \
						--member="serviceAccount:$$DEST_SERVICE_ACCOUNT" \
						--role=roles/compute.admin \
		; fi && \
		if (( $$(gcloud iam service-accounts get-iam-policy \
				$$DEST_SERVICE_ACCOUNT \
				--project=$(MI_PROJECT_DEST) \
				--filter="bindings.members:user:$(USER)@$(ORG)" \
				--format="value(bindings.role)" \
				| wc -l ) < 1 )); then \
					echo "bind $(USER)@$(ORG) to $$DEST_SERVICE_ACCOUNT" && \
					gcloud iam service-accounts add-iam-policy-binding \
						$$DEST_SERVICE_ACCOUNT \
						--project=$(MI_PROJECT_DEST) \
						--member="user:$(USER)@$(ORG)" \
						--role="roles/iam.serviceAccountUser" \
		; fi && \
		if (( $$(gcloud compute instances list \
				--project=$(MI_PROJECT_DEST) \
				--format="value(status)" \
				--filter=name:"$(MACHINE_IMAGE)" 2>/dev/null | wc -l) < 1 )); then \
				echo "creating $(MACHINE_IMAGE) instance in $(MI_PROJECT_DEST)" && \
				gcloud beta compute instances create "$(MACHINE_IMAGE)" \
					--project=$(MI_PROJECT_DEST) \
					--source-machine-image="projects/$(MI_PROJECT_SOURCE)/global/machineImages/$(MACHINE_IMAGE)" \
					--service-account="$$DEST_SERVICE_ACCOUNT" \
		; fi && \
		gcloud beta compute machine-images create \
			"$(MACHINE_IMAGE)" \
			--project=$(MI_PROJECT_DEST) \
			--source-instance="$(MACHINE_IMAGE)" && \
		gcloud compute instances delete \
			--project=$(MI_PROJECT_DEST) \
			"$(MACHINE_IMAGE)" \
	; fi

## tf: build terraform using *.tf files in current directory building COUNT instances
COUNT :=
.PHONY: tf
tf: tf-lint
	terraform plan $(TF_VARS)
	terraform apply $(TF_VARS)

## tf-lint: check if terraform plan is valid
.PHONY: tf-lint
tf-lint:
	terraform init -upgrade
	terraform show
	terraform fmt
	terraform validate

## terminated: terminate an instance which keeps it from costing money
.PHONY: terminated
terminated: tf-lint
	terraform plan $(TF_VARS) -var="desired_status=TERMINATED"
	terraform apply $(TF_VARS) -var="desired_status=TERMINATED"


## destroy: uninstall all the terraform plan with target DESTROY_TARGET
.PHONY: destroy
TARGET ?=
ifdef DESTROY_TARGET
	TARGET := $(DESTROY_TARGET)
endif
ARGS ?=
ifdef FORCE
	ARGS += -var="prevent_destroy=false"
endif
destroy: tf-lint
ifdef DESTROY_TARGET
	@echo debug: destroy target is $(DESTROY_TARGET)
endif
	@echo debug: ARGS is $(ARGS) TARGET is $(TARGET)
	terraform plan $(TF_VARS) $(ARGS) $(TARGET)
	terraform destroy $(TF_VARS) $(ARGS) $(TARGET)


## password: reset the windows password this cannnot be run from terraform
.PHONY: password
password:
	gcloud beta compute reset-windows-password $(MACHINE) --project $(DEFAULT_PROJECT)

## ssh: ssh into terraform
.PHONY: ssh
ssh:
	eval ssh "$$(terraform output ip)"

## service-account: Create a service account
# https://cloud.google.com/sdk/gcloud/reference/auth/activate-service-account
# https://cloud.google.com/iam/docs/creating-managing-service-accounts
			#--role=roles/compute.osLogin
.PHONY: service-account
service-account:
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
