# Makefile includes

These are the standard includes:

include.mk is required and has help and configuration used for all

The others are for specific purposes:

include.python.mk is for python development
include.airflow.mk for using Apache airflow
include.docker.mk for docker managemen

## Installation

This library is used by the parallel richtong/bin repo and you should put them
next to each other. Normally you want to fork the repo

```shell
cd ~/ws/git
gh fork git@github.com:richtong/lib
gh fork git@github.com:richtong/bin
cd src
git submodule add git@github.com/_yourrepo_/lib
git submodule add git@gihtub.com/_yourrepo_/bin
git submodule update --init lib bin
cd lib
git remote add upstream git@github.com/richtong/lib
cd ../bin
git remote add upstream git@github.com/richtong/bin
```

Then when you make a change or and want to merge from upstream
then you just need to

```shell
cd ~/ws/git/_yourrepo_/bin
git pull --rebase upstream master
# deal with any conflict
git push
```
