# Rich's Fine Library functions

These are open source versions of @richtong's library functions

## Installation

The easiest thing to do is at the route of your project, let's call it `src` is
to do

```shell
mkdir -p ~/ws/git
cd ~/ws/git
git clone git@github.com:_your_project_/src
cd src
mkdir rt
cd rt
git submodule add git@github.com:richtong/lib
```

If you want to install pre-commit checks then `make pre-commit` will do that.

Feel free to submit pull requests

## Shell libraries and includes

These are standard libraries, it starts with adding include.sh to the script.
There is a template for usage in `install-1password.sh`



## Makefile includes

These are the standard includes:

include.mk is required and has help and configuration used for all

The others are for specific purposes:

include.python.mk is for python development
include.airflow.mk for using Apache airflow
include.docker.mk for docker managemen
