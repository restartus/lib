# note tables not compatible with 3.9
##
## Notebook Commands
## ----
PYTHON ?= 3.8
PACKAGES+=make vim gosu
PIP+=pandas confuse ipysheet h5py ipywidgets ipympl ipyvuetify \
     scipy altair xlrd bqplot ipyvolume restart==2.6.7 restart_datasets voila
PIP_ONLY+=tables qgrid

NOTEBOOK ?= notebook.ipynb


## docx: Convert from .ipynb to .docx
.phony: docx
docx:
	pandoc $(NOTEBOOK) -s -o "$$(basename -s ipynb "$(NOTEBOOK)")docx"
