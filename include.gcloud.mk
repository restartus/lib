#
##
## Gcloud commands
## --------------
#
#
PROJECT_ID ?= $(USER)-1
# https://cloud.google.com/about/locations/
# us-west1: Oregon,  us-west2: LA, us-west3: SLC, us-west4: las vegas
#
REGION ?= us-west1
ZONE= ?= $(REGION)-b
CLUSTER ?= cluster-$(USER)-1


# https://cloud.google.com/compute/docs/gcloud-compute#default-properties
## init: Gloud init sets the login and your default zones and project
.PHONY: init
init:
	gcloud projects list
	gcloud init
	gcloud computer project-info add-metadata \
		--metadata google-compute-default-region=$(REGION),google-computer-default-zone=$(ZONE)

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
	if ! gcloud container clusters list --format="value(name)" | grep -q "$(PROJECT_ID)"; then \
		gcloud container clusters create-auto $(CLUSTER) \
			--region $(REGION) \
			--project $(PROJECT_ID) \
	; fi
	gcloud container clusters get-credentials $(CLUSTER) \
		--region $(REGION) \
		--project $(PROJECT_ID)
	kubectl cluster-info
	kubectl get nodes
