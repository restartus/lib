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
CLUSTER ?= cluster-$(USER)-1

## init: Gloud init sets the login and your default zones and project
.PHONY: init
init:
	gcloud projects list
	gcloud init

# https://cloud.google.com/kubernetes-engine/docs/how-to/creating-an-autopilot-cluster
## autopilot: Creates a GKE autopilot cluster
.PHONY: autopilot
autopilot:
	gcloud container clusters create-auto $(CLUSTER) \
		--region $(REGION)
		--project=$(PROJECT_ID)

