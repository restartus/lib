# Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Directory Layout](#directory-layout)
- [Guide For Developers Looking to Start Contributing to This Project](#guide-for-developers-looking-to-start-contributing-to-this-project)
- [Gitpod Workspace](#gitpod-workspace)
  - [Set Up You're First Workspace](#set-up-youre-first-workspace)
  - [Guide to Development with Gitpod](#guide-to-development-with-gitpod)
    - [Workspace Start and Stop Functionality](#workspace-start-and-stop-functionality)
    - [Creating a Workspace from a Specific Branch](#creating-a-workspace-from-a-specific-branch)
    - [Multiple Workspaces](#multiple-workspaces)
    - [Git commands](#git-commands)
    - [Accessing Submodules](#accessing-submodules)
    - [Adding Dependencies and the .gitpod.Dockerfile](#adding-dependencies-and-the-gitpoddockerfile)
    - [Running Jupyter Notebook in a Workspace](#running-jupyter-notebook-in-a-workspace)
- [Prerequisites](#prerequisites)
  - [Install Homebrew](#install-homebrew)
  - [Install Python](#install-python)
  - [Install Pipenv](#install-pipenv)
  - [Install GitHub CLI](#install-github-cli)
- [Using Windows](#using-windows)
  - [Installing WSL](#installing-wsl)
  - [Using WSL](#using-wsl)
- [Cloning This Repo](#cloning-this-repo)
  - [Long Guide](#long-guide)
    - [Verifying Your Directory Structure is Compatible](#verifying-your-directory-structure-is-compatible)
    - [Guide for Working on Multiple Projects](#guide-for-working-on-multiple-projects)
- [Short Guide for working with submodules](#short-guide-for-working-with-submodules)
  - [Short Guide](#short-guide)
- [Git Submodules](#git-submodules)
  - [Accessing and Contributing to Submodules](#accessing-and-contributing-to-submodules)
  - [New Submodules Added to Master](#new-submodules-added-to-master)
  - [The Data Submodule](#the-data-submodule)
  - [Updates to Submodules](#updates-to-submodules)
- [Configuring Development Environment](#configuring-development-environment)
- [Feature Development, Rebasing, and Pull Requests](#feature-development-rebasing-and-pull-requests)
  - [Adding New Features](#adding-new-features)
  - [Pushing Commits to the Remote Repository](#pushing-commits-to-the-remote-repository)
  - [Submitting Pull Requests to Merge Changes into the Master Branch](#submitting-pull-requests-to-merge-changes-into-the-master-branch)
  - [Submitting Pull Requests to Merge Changes into the Master Branch next](#submitting-pull-requests-to-merge-changes-into-the-master-branch-next)
    - [Reviewing Pull Requests as a Maintainer](#reviewing-pull-requests-as-a-maintainer)
    - [Merging Pull Requests as a Maintainer](#merging-pull-requests-as-a-maintainer)
- [Overview of Git Operations](#overview-of-git-operations)
  - [Merging (Don't Do This)](#merging-dont-do-this)
  - [Rebasing](#rebasing)
  - [Squashing](#squashing)
  - [Putting Everything Together](#putting-everything-together)
  - [What To Do When You Check in Files You Didn't Mean To](#what-to-do-when-you-check-in-files-you-didnt-mean-to)
  - [Viewing Commit History through Terminal](#viewing-commit-history-through-terminal)
- [Development Practices and Tools We Use](#development-practices-and-tools-we-use)
  - [Project Tempo](#project-tempo)
    - [Weekly Sprint](#weekly-sprint)
  - [Cadence](#cadence)
  - [Daily Scrum](#daily-scrum)
- [Best Practices](#best-practices)
- [Environment Variables](#environment-variables)
- [Airflow](#airflow)
- [Project Planning](#project-planning)
  - [Creating an Issue](#creating-an-issue)
- [Google Foo](#google-foo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Directory Layout

![Code Lint](https://github.com/restartus/src/workflows/Code%20Lint/badge.svg)

This repo will house all of the source code for this project.

To greatly reduce the size of this repo, we've moved what previously was
`src/extern/covid-projection/data` to its own repo, which can be found
[here](https://github.com/restartus/data). Instructions for using this data can
be found [here](https://github.com/restartus/data/blob/lucas-doc/README.md).

Currently, this repo's directory layout has these major areas:

- [extern](extern). This contains several GitHub repos as submodules. The most
  important of these are [covid-projection](extern/covid-projection), which
  houses the source code for the Restart Partners model, and
  [data](extern/data), which houses all of the data that we use. More
  information on how we use Git submodules can be found [here](#git-submodules)
- [lib](lib) Developer tools, Makefiles, and scripts for environment control.
- [bin](bin). Mostly bash scripts for common, repetitive tasks that can be automated.
- [user](user). Contains various experimental code.

## Guide For Developers Looking to Start Contributing to This Project

## Gitpod Workspace

If you are set on with developing on your local machine, navigate to
[Prerequisites](#prerequisites) to get set up.

If you do not want to deal with machine compatability, installations, etc, but still
want to have access to a complete development environment for contributing to this
project, you can leverage our preconfigured Gitpod cloud-hosted development environment,
accessible through a Chrome browser tab.

### Set Up You're First Workspace

You'll only have to do these steps once :)

1. Make sure you have Google chrome installed, a Github account set up, and an
   OpenSSH public/private rsa key pair (and make sure you know your
   passphrase).  If you don't recall your passphrase, see
   [here](https://docs.github.com/en/github/authenticating-to-github/recovering-your-ssh-key-passphrase).
1. Install the Gitpod chrome browser extension located
   [here](https://chrome.google.com/webstore/detail/gitpod-dev-environments-i/dodmmooeoklaejobgleioelladacbeki/related).
1. Make a gitpod account through using your Github account [here](https://gitpod.io/login/).
1. Navigate to [here](https://gitpod.io/settings/) and do the following:
  a. Create an environment variable by clicking the add variable button.
  b. Name this variable `SSH_PUBLIC_KEY` and copy and paste your rsa public key
  in the value field.
  c. Set Organization/Repository to be `restartus/*`.
  d. Click the check box to confirm.
  e. Repeat steps a to d for the name `SSH_PRIVATE_KEY` but copy and paste only
  the portion of your rsa private key between the header and footer.  i.e. only
  lines in: that are between the OPENSSH PRIVATE KEY lines. The
  reason for doing this is that Gitpod's textbox removes newline characters.
  Thus, in each start of a workspace, the key is parsed and reformatted to be
  in the expected OpenSSH format.
1. Navigate in your browser to [restart/src](https://github.com/restartus/src).
1. Click on the green Gitpod button that appears in between the Code button and
   About section toward the top right (refresh page if it is not present).
1. Login with Github and authorize gitpod.
1. Grant access and authorize once again if prompted.
1. A new tab will open with Gitpod's Theia IDE. It will likely take ~1 min to
   build. Once it has finished, you should have a fully capable development
   environment set up!

You’ll notice that most of everything is set up as if you are working on a
local machine!

Until our repository is public, you will have 50 hours of workspace
uptime to use over 30 days before needing to set up a paid
subscription.

As soon as our repository is public, everything will be free,
but you will still be limited to 50 hours of uptime per month.
Gitpod offers student discount subscriptions and offers to extend
the hours per month if you are an professional open source developer.
See [here](https://www.gitpod.io/pricing/) for more info.

One thing you might notice is that the directory structure
is slightly different from the one described below.

As of now, the directory structure will have the restartus/src
repository located in /workspace/src.

An important thing to note is that anything outside of
/workspace/src will not be saved between workspace starts
and stops.

### Guide to Development with Gitpod

#### Workspace Start and Stop Functionality

You can view your workspaces at [gitpod](https://gitpod.io/workspaces/)
At this page you can start, stop, delete, etc. workspaces that
you've created.

Stop a workspace when you're not working in it, as this will
prevent useless consumption of the limited workspace uptime that
you have.

When you want to resume work in a workspace, you simply start it
back up.

Only delete a workspace when you are completely done with it.

Workspaces that are inactive for 14 consecutive days will auto-
matically be deleted.

#### Creating a Workspace from a Specific Branch

If you want to create a workspace from a specific branch,
simply change the branch displayed on the Github webpage
using the branch dropdown menu before clicking the Gitpod button.

#### Multiple Workspaces

As you probably have already figured out, you can create multiple
workspaces. You can even work in multiple workspaces at once!

An instance where you use multiple workspaces would be if you
are working on two different features at once and each requires
different new dependencies.

#### Git commands

All git commands should work as if on a local machine.  See
[here](#git-submodules),
[here](#feature-development-rebasing-and-pull-requests), and
[here](#overview-of-git-operations) for guides and best practices related to
git.

#### Accessing Submodules

The first time you start any particular workspace, you'll have
to run

```bash
git submodule init
```

and then

```shell
git submodule update <submodule>
```

for each submodule you wish to clone and use. The same goes
for submodules within other submodules.
You will be asked for your rsa key passphrase for each clone.

Note that you may have to do (before you've made any changes)

```bash
cd <submodule>
git checkout master
git reset --hard origin/master
```

on a submodule you update to get the most updated master.

More on submodules [here](#git-submodules).

#### Adding Dependencies and the .gitpod.Dockerfile

This file specifies all the dependencies needed to run your
workspace. It should come with everything you need for what we
have currently, but if you want to add other dependencies, you
simply add them to this Dockerfile from your current workspace,
push to a new branch, and create a new workspace from that branch.

Here is a typical development scenario involving new dependencies:

1. You create a workspace from the master branch of src.

1. You create a new branch from inside this workspace.

1. You add the dependencies you want to the .gitpod.Dockerfile on
   this branch.

1. You add and commit the changes to the .gitpod.Dockerfile and
   push them to origin/your-new-branch.

1. You then create a new workspace from that branch, and voila,
   you have your added dependencies and are ready to start working
   with them.

This way, after you've implemented changes on your new branch and
are ready to submit a PR, the required dependencies are already in the
.gitpod.Dockerfile for the next developer.

#### Running Jupyter Notebook in a Workspace

To run jupyter notebooks in a workspace, run

```bash
jupyter notebook
```

just as usual! The UI should open in a new browser tab automatically.

The first time it opens, you'll have to enter a token that appears in the
urls displayed in terminal while jupyter is running. This is for
security purposes. After that, you'll be directed straight to the
UI, no tokens asked.

Note that for now, you can't run a notebook directly by

```bash
jupyter notebook <some-notebook>.ipynb
```

You have to select the notebook from the browser tab that opens.

## Prerequisites

We currently support MacOS as a development environment.

In order to begin contributing to this project, please ensure that the
following packages are installed:

- Homebrew ([install here](#install-homebrew))
- Python ([install here](#install-python))
- Pipenv ([install here](#install-pipenv))
- GitHub CLI ([install here](#install-github-cli))

### Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

### Install Python

``` bash
brew install python
```

### Install Pipenv

```bash
brew install pipenv
```

### Install GitHub CLI

```bash
brew install github/gh/gh
```

## Using Windows

Windows 10 can be used as a development environment via Windows Subsystem for
Linux (WSL).

### Installing WSL

Windows Subsystem for Linux can be installed by enabling the feature through Windows
PowerShell. From there you can install a Linux distribution from the [Microsoft Store](https://aka.ms/wslstore).
Detailed instructions can be found on [Microsoft's website](https://docs.microsoft.com/en-us/windows/wsl/install-win10).

### Using WSL

After setting up WSL and installing a Linux distribution, you can open the
Linux distribution to bring up a Linux command line. After setting up the Linux
virtual machine, you can follow the usual steps to [clone the
repo](#cloning-this-repo) as if you were using a Linux computer.

## Cloning This Repo

We have scripts that will search your machine for a directory called `ws/git` in
order to run the code associated with this project. For a short, copy/paste
friendly guide, see [this shortened guide](#short-guide). For a more verbose
explanation, see [this longer guide](#long-guide).

### Long Guide

```bash
mkdir -p ~/ws
cd ~/ws
mkdir git && cd git
```

#### Verifying Your Directory Structure is Compatible

First verify that the directory `~/ws` exists:

```bash
cd ~
ls | grep ws
```

This should output:

```bash
ws
```

Next, verify that the directory `~/ws/git` exists:

```bash
cd ~/ws
ls | grep git
```

This should output:

```bash
git
```

If your directories are correctly structured, clone the `src` repo into
`~/ws/git`:

If you don't have SSH keys setup for GitHub:

```bash
cd ~/ws/git
git clone https://github.com/restartus/src.git
```

You'll be prompted for your GitHub password.

If you do have SSH keys setup for GitHub:

```bash
cd ~/ws/git
git clone git@github.com:restartus/src.git
```

To ensure that everything has been correctly configured, run:

```bash
  cd ~/ws/git/src
  ls
```

This should output something that looks like this:

```bash
README.md     bin     env     extern      user
```

For more information on best practices for scientific python, see [this blog
post](https://calvintong.com/2020/03/14/on-scientific-python-best-practices/) by
[@calvinytong](https://github.com/calvinytong).

#### Guide for Working on Multiple Projects

If you're working on multiple projects using this same directory structure, it's
important that the project you're currently working on contains a `ws/git`
directory in it somewhere in order to prevent filepath-related bugs. We propose
the following method for organizing and switching between projects.

Say that in addition to `restartus`, I'm also working on a project called
`proj`. Since I'm currently working on `restartus`, its `src` repo can be found
in my `~/ws/git` directory. I'd keep the `src` repo for `proj` in a directory
called `~/ws.proj/git`. If I wish to stop working on `restartus` for the day and
instead work on `proj`, I simply need to change `ws` to `ws.restartus` and then
change `ws.proj` to `ws`. Now, all the scripts in `proj` that look for `ws/git`
will work correctly. This can be achieved through: `

```bash
mv ~/ws ~/ws.restartus mv
~/ws.proj ~/ws
```

When returning to work on this project and running any of our scripts, be sure
to undo this (by changing `ws` back to `ws.proj` and `ws.restartus` to `ws`).

## Short Guide for working with submodules

### Short Guide

If you use SSH keys:

```bash
mkdir -p ~/ws/git && cd ~/ws/git
git clone git@github.com:restartus/src.git
```

If you use HTTPS to clone:

```bash
cd ~/ws/git
git clone https://github.com/restartus/src.git
```

## Git Submodules

### Accessing and Contributing to Submodules

The code in this project depends on several other GitHub repositories. In order
to use these repositories while keeping our own code stable, we use Git
submodules to version control modules that we depend on.

Once you have cloned this repository, you'll need to run some more commands to
access the submodules that we use. With this directory as your root, run the
following commands (you'll only need to do this once):

```bash
cd extern
git submodule init
```

From here, if you need a submodule you can simply use `git submodule update` to
download its contents onto your machine. For example, if you need to access the
`covid-projection` submodule (once again assuming `src` as a root directory for
relative paths):

```bash
cd extern && git submodule update covid-projection
cd covid-projection
```

At this point if you run a `git status` you will notice you are in detached
HEAD mode - this is because a submodule is in fact its own GitHub repository,
and when you access it you are viewing a specific commit in the history. If you
plan on making additions to the `covid-projection` repository, you'll need to
switch to its master branch and then create a feature branch of your own:

```bash
git checkout master
git checkout -b <branchname>
```

At this point, Git will behave exactly as if you are in the `covid-projection`
repository, because you really are!

### New Submodules Added to Master

In the event that new submodules are added to the master branch, you'll
have to take some special actions. See [this README](extern/README.md)

### The Data Submodule

The `data` submodule is where all of the data used in this project resides, and
as a result it is quite massive (15+ GB). To avoid lengthy download times, all
the data in this directory is contained in submodules as well (so from the
point of view of `src`, submodules within submodules). As an example we'll show
the commands you'd need to run to access the `ingestion` directory, which
contains data needed to run the model in `covid-projection`. Again assuming
`src` as the root of relative paths:

```base
cd extern && git submodule update data
cd data
git submodule update ingestion
```

This will download only the files in the `ingestion` directory.

### Updates to Submodules

If a particular submodule is modified, by default your `git status` will only
tell you that there was a change in the submodule, but not exactly what that
was. To bump the submodule in your branch to the latest version, simply run
`git submodule update <name>`. This will change the pointer in the `extern`
directory to point to the latest commit in that submodule's history. Note,
however, that if your code depends on the submodule you're thinking about
updating, you should think carefully and inspect what changes were made before
you bump - the modifications may very well break your code.

If you want your `git status` to give you more information about the commits
being made inside submodules, run this command once:

```bash
git config --global status.submoduleSummary true
```

## Configuring Development Environment

We use Pipenv to ensure consistent software versions and packages.

A brief tutorial on pipenv can be found
[here](https://medium.com/@MattGosden/pipenv-for-easier-virtual-environments-69e1e520cde8).
In general, we'll be using different environments in each directory during
development (as opposed to a single environment for the whole project). [This
file](lib/include.python.mk) is our, python-optimized
[Makefile](https://opensource.com/article/18/8/what-how-makefile) that contains
several useful targets - it can automatically build your Pipfile with all the
dependencies (packages, language versions, etc.) we need. Below is an example of
creating a new directory in `src` and then building a pipenv virtual
environment. We suggest
[symlink](https://unix.stackexchange.com/questions/68368/what-is-symlinking-and-how-can-learn-i-how-to-to-do-this#:~:text=Up%20vote%202,target%3E%20eg.)ing
it in your working directories, and then using a `Makefile` to override what you
need.

```bash
cd ~/ws/git/src
mkdir test && cd test

# Creating a symlink to the python include file
ln -s ../lib/include.python.mk

# Quickly creating a compatible makefile
echo "include include.python.mk" >> Makefile

# Building pipenv
make pipenv
```

Pipenv is a bit slow to download all dependencies, but the above commands should
create a new virtual environment with the default dependencies specified by
`include.python.mk`. Make sure that you don't have any other virtual
environments running at this time (conda, for example). You can run this virtual
environment by:

```bash
pipenv shell
```

## Feature Development, Rebasing, and Pull Requests

We generally want to avoid working directly on the master branch while adding
new features - it's the job of the maintainers to ensure it is stable and clean.
For this reason, anytime a new feature needs to be added the best practice is to
create a feature branch, implement changes there, and eventually merge this back
into the master branch upon testing and review. This is our workflow:

### Adding New Features

- First, check to ensure that master is clean/updated to the newest version, and
- force fast-foward merging (to ensure we don't have ugly merge-commits):

  Make sure you have the newest version of the master branch

  ```bash
  git checkout master
  git pull
  ```

- If everything is clean and up-to-date, go ahead and create a branch (branches
- should conventionally be named "yourname-yourfeature"):

  `git checkout -b branchname`

- You'll make all of your changes in this branch, frequently committing as you
- see fit. If you see that changes have been made to the master branch, rebase
- your branch onto the newest version of master:

First, make sure you have the latest master:

  ```bash
  git checkout master
  git pull
  ```

  Now rebase your branch onto it:

  ```bash
  git checkout branchname
  git rebase master
  ```

If there are conflicts (some of the changes in master are in the same files
you're editing), you'll be prompted to manually resolve the conflicts. When
you've taken care of the offending files, commit them and use `git rebase
--continue` to finish up the rebase. Remember to always test your code after
rebasing to make sure that it didn’t break anything.

### Pushing Commits to the Remote Repository

To push your local commits to the remote repository:

```bash
git push origin yourbranch
```

This will upload changes to your branch from your local repository to the
remote repository which will help keep things synchronous between the two.
Even if it is your first time pushing on your branch, do not ever flag -u. Git
will take care of creating an upstream if it is needed.

### Submitting Pull Requests to Merge Changes into the Master Branch

Done with the feature you were working on? Great! Before submitting a pull
request, however, rebase and squash your commits to create as concise,
human-readable a commit history as is reasonably possible. Make sure your local
master is updated with the remote repository, and then perform an interactive
rebase to squash your commits:

  ```bash
  git checkout master
  git pull
  git checkout yourbranch
  git rebase -i master # Interactive rebase
  ```

Upon running this last command, a text editor will open with something looking
like this:

  ```bash
  pick  b001 message for commit #1
  pick  b002 message for commit #2
  pick  b003 message for commit #3
  pick  b004 message for commit #4
  ```

Let's say I want to rewrite the messages for commits b002 and b003 into a
single message that I'll reword, and disregard the message for commit b004.
In the editor, to consolidate commit messages change each affected commit's
`pickup` to `squash`. To disregard the commit message, change `pick` to
`fixup`.

  ```bash
  pick   b001 message for commit #1
  squash b002 message for commit #2
  squash b003 message for commit #3
  fixup  b004 message for commit #4
  ```

You'll then be prompted with an editor to write a new commit message combining
b002 and b003. After this has been saved, we've successfully rebased, and our
four commit messages have been consolidated into two.

The point of this is making code reviews as painless as they can be. Ideally,
commits should all be descriptive of a substantive change (i.e squash away stuff
like "fixed typo"), and are small enough so they only represent relatively
self-contained issues.

At this point, a `git status` will output something like:

  ```bash
  Your branch and 'origin/yourbranch' have diverged,
  and have X and X different commit(s) each, respectively.
  ```

This is because rebases are rewriting history. First history looked like this
(note that each letter represents a commit, which can be thought of a snapshot
of the entire directory at a specific moment in time):

  ```bash
  ... o ----- o ----- A ----- B master, origin/master
                       \
                        C yourbranch, origin/yourbranch
  ```

But now we've made it look like this:

  ```bash
  ... o ----- o ----- A --------------------------------------- B master, origin/master
                       \                                         \
                        C origin/yourbranch                       C yourbranch
  ```

To fix this problem, we need to overwrite origin/yourbranch with yourbranch.
This involves a force push, and is a bit scary. Remember, we're rewriting
history here, so only do this once you're sure you've correctly rebased and
your changes are ready to be pushed:

  `git push origin yourbranch --force`

  Now we all agree on a common history that looks like:

  ```bash
  ... o ----- o ----- A ----- B master, origin/master
                               \
                                C yourbranch, origin/yourbranch
  ```

Make sure to always test your code after a rebase - especially if the changes
to the master branch involved files you're currently working on (in which case
you likely had to deal with merge conflicts), or files that your code depends
on, your code very well may now be broken and require some retooling.

### Submitting Pull Requests to Merge Changes into the Master Branch next

Done with the feature you were working on? Great! Before submitting a pull
request, however, rebase and squash your commits to create as concise,
human-readable a commit history as is reasonably possible. Make sure your local
master is updated with the remote repository, and then perform an interactive
rebase to squash your commits:

  ```bash
  git checkout master
  git pull
  git checkout yourbranch
  git rebase -i master
  ```

The `-i` flag will prompt a text editor to open with something looking like this:

  ```bash
  pick  b001 message for commit #1
  pick  b002 message for commit #2
  pick  b003 message for commit #3
  pick  b004 message for commit #4
  ```

Let's say I want to rewrite the messages for commits b002 and b003 into a
single message that I'll reword, and disregard the message for commit b004. In
the editor, to consolidate commit messages change each affected commit's
`pickup` to `squash`. To disregard the commit message, change `pick` to
`fixup`.

  ```bash
  pick   b001 message for commit #1
  squash b002 message for commit #2
  squash b003 message for commit #3
  fixup  b004 message for commit #4
  ```

You'll then be prompted with an editor to write a new commit message combining
b002 and b003. After this has been saved, we've successfully rebased, and our
four commit messages have been consolidated into two.

Once again, resolve any conflicts and then realign the remote branch (likely
`origin`) and your local with `git push origin yourbranch --force`.

The point of this is making code reviews as painless as they can be. Ideally,
commits should all be descriptive of a substantive change (i.e squash away stuff
like "fixed typo"), and are small enough so they only represent relatively
self-contained issues. Lastly, test your code one last time - it's a great
habit!

- Open a pull request and set up a code review:

Using the GitHub CLI, this can all be done from the command line:

  `gh pr create`

This will prompt a screen in your terminal asking you to title the pull request,
and open an editor for you to explain in more detail. In here, include a concise
description of what changes are being made and why they're being made.

This can also easily be done on the GitHub online UI - navigate to the `Pull
requests` tab and select `New pull request`.

Creating the pull request should notify
[@lucasthahn](https://github.com/lucasthahn) and
[@richtong](https://github.com/richtong), who will set up a code review. All
pull requests require two review approvals before they can be merged into the
master branch.

#### Reviewing Pull Requests as a Maintainer

If you are a maintainer, you have the resposibility of reviewing pull requests.
The steps for doing so are broken out below.

The only maintainers are currently [@lucasthahn](https://github.com/lucasthahn)
and [@richtong](https://github.com/richtong). However, as a contributor,
it is important to know the review process so that you can get
your code, branch, etc. into a state that allows your PR reviewer to
focus on architectural and other more important aspects of your PR than
things like poor code practice etc.

- Review any comments that have been made by the issuer. Doing so will provide
  context likely needed for the review process. The history of the PR and any
  comments that have been made will appear under the "Conversation" tab of the
  PR's github webpage.
- Go through the PR's commits to see an overview of the changes that have
  been made. Make sure that there aren't too many commits/messages, and if
  there are, ask the issuer to do an interactive rebase to squash and fixup
  commits accordingly. Unsurprisingly, the PR's commits can be viewed under
  the "Commits" tab.
- Next, ensure that lints and any other checks have succeeded/passed.
  This can be viewed under the "Checks" tab. Detailed breakdowns of a check
  can be viewed by simply clicking on it.
- If all looks good so far, you must then review the file changes
  for any remaining deficiencies in code, design, etc. You can add comments
  to specific lines in files by hovering your mouse over the plus sign
  at the left of each line. These comments are how you can request the
  issuer to make any any changes that are necessary before merging the PR into
  master.
- Finally, if everying checks out you can rebase and merge the PR's branch
  into master.

#### Merging Pull Requests as a Maintainer

If everything checks out and the pull request can go through, we still want to
avoid unneccessary merge commits and maintain a linear, easily readable commit
history on master. This can be done through the command line using the GitHub
CLI (which we installed earlier):

  ```bash
  git checkout master
  git pull
  gh pr merge yourbranch
  ```

This will prompt you with three options:
    (1) Create a merge commit
    (2) Rebase and merge
    (3) Squash and merge

Select rebase and merge. This way, the branch's commits - which should have been
squashed and reviewed by this point - are simply added to the tip of master, and
the commit history remains concise, substantive, and linear.

Background on the Git operations at play during this process can be found [here](#overview-of-git-operations)

## Overview of Git Operations

While Git can be intimidating at first and the commands seem abstract and
esotaric, once you have a bit of an intuition for what the operations are
actually doing, it will start to make much more sense and you'll be able to take
advantage of its powerful capabilities.

### Merging (Don't Do This)

The guide below describes how you'd go about merging two GitHub branches
together. You won't be doing this in this project, but it's good to understand
what this does to explain exactly why we don't do it.

```bash
git checkout -b newbranch1
git checkout -b newbranch2
```

Say that a few commits have been made to newbranch2, and now we want to merge
those into newbranch1. This can be achieved using the following:

```bash
git checkout newbranch1
git merge newbranch2
```

What exactly happened here? When we created newbranch1, and newbranch2, they
both split off of the same exact commit in the master branch, and were allowed
to grow separately while staying connecting at this common ancestor. However,
when we merged newbranch2 into newbranch1, we've spliced them back together - a
new **merge commit** is created (assuming there are no conflicts), and this
commit contains all the changes made in both newbranch1 and newbranch2 up to
that point in time. Merging isn't a destructive action, so all the commits we
made in newbranch still exist, but now master contains all the code we need.
However, the merge-commit is ugly, doesn't describe any substantive changes that
were made, and makes the commit history just a bit harder to understand. For
these reasons, **never merge anything into master**. This is why we use pull
requests and rebasing, to ensure that the master branch always remains coherent.

### Rebasing

Let's say I'm about to start working on a new feature, so I create a development
branch off of the master branch

`git checkout -b dev-branch`

The **base** of this commit would be the latest commit of the master branch -
for simplicity, let's call this commit a001. This is great; I'm free to make all
the changes I'd like to my newly created dev-branch without infecting the master
branch with my horrible, ugly code. However, let's say it's been a few days and
changes have been made to master - now it's on commit a005. This is potentially
problematic, since the origin of dev-branch is commit a001; what if a bug was
found in master and fixed? Perhaps this code is essential to the development of
my new feature. Rebasing here could be very useful - we can change history by
making it seem like the **base** of dev-branch was never commit a001, but
instead commit a005, the latest version of master. Assuming I'm still on
dev-branch, this can be achieved as follows:

`git rebase master`

The origin of dev-branch is now commit a005, which means the commit history is
linear and the upstream changes that were made to master are now incorporated
into dev-branch. In other words, we've added all the commits of dev-branch to
the tip of master. Note that no **merge-commit** is created here.

Even more powerful is interactive rebasing. Say I have three commits in
dev-branch, when I run `git rebase -i master` I'll see the following in a text
editor:

```bash
pick  b001 message for commit #1
pick  b002 message for commit #2
pick  b003 message for commit #3
pick  b004 message for commit #4
```

Let's say I want to rewrite the messages for commits b002 and b003 into a single
message that I'll reword, and disregard the message for commit b004. In the
editor, to consolidate commit messages change each affected commit's `pickup` to
`squash`. To disregard the commit message, change `pick` to `fixup`.

```bash
pick   b001 message for commit #1
squash b002 message for commit #2
squash b003 message for commit #3
fixup  b004 message for commit #4
```

Once I save and quit, assuming there were no conflicts, we'll have successfully
rebased onto master and squashed commits b002 and b003 into a single message,
and disregarded the message for commit b004. However, all my work is still
there. Although we branched off of master with dev-branch, through rebasing
we've maintained a clear, linear project history.

### Squashing

This does a similar thing to interactive rebasing, but with a bit broader
brush-strokes. Say I run the following:

```bash
git checkout master
git merge --squash dev-branch
git commit -m "added feature in dev-branch"
```

All of the commits I previously made in dev-branch have been **squashed** into a
single commit, with the message "added feature in dev-branch" - this single
commit, which contains all of the changes from dev-branch, is then added to the
top of tip of master. Note once again that no merge commit has been created.

Now, when I save and close the file commits #1 and #2 will have been
**squashed** into a single commit - both of their changes have been recorded,
but we're left with a much more human-readable, clear project history.

### Putting Everything Together

It's good practice to commit very frequently when you're working on new
features. Given this fact, interactive rebasing is a very powerful tool,
allowing us to streamline the code review process and maintain a cohesive,
linear structure in our master branch.

### What To Do When You Check in Files You Didn't Mean To

In the case that you check in files that you didn't mean to or that are
unneeded, you'll need to run

```bash
git checkout <your branch (not master!)>
git rm -r --cached <file_path/file_name>
git commit -m "removed <file_path>/<file_name> from git index"
```

for each file you want to untrack. What this is doing is removing
these files from the git index which tells git which files to keep track of.

If the number of files you need to remove is large enough to make
running these commands for each file a hassle, see these:

- To remove all files of type `.<type>`

    ```bash
    git rm -r --cached *.<type>
    ```

- To remove all files in `<dir>`:

    ```bash
    git rm -r --cached <dir>
    ```

More on special pattern matching [here](https://git-scm.com/docs/gitignore).
And don't forget to commit once you've removed your desired files.
You can check if you've removed them by

```bash
git ls-tree -r <your branch> --name-only
```

Why untrack these files if they are harmless?
Files like .log files can have very large sizes and even if it is removed
from the directory of a certain branch, git will still track them, which
means every time someone pulls or pushes, that's a bunch of meaningless data
getting pushed around, which is inefficient and unwanted.

### Viewing Commit History through Terminal

If you want to have access (for whatever reason) to a previous commit,
you can view all previous commits with the
following command:

```bash
git log --reflog
```

You can checkout to a past commit by its reference number via

```bash
git checkout <commit-ref>
```

## Development Practices and Tools We Use

### Project Tempo

#### Weekly Sprint

Each week we'll create a new milestone in the GitHub issues. This is where we'll
stick all the open issues that we hope to get done for the entire week.
Everything you're working on should have a GitHub issue attached - if it
doesn't, create one! You can self-assign the issue, or if you're depending on
someone else's work you can link them in as well.

The format we use for issues is [X] IssueTitle (Y), where X is the amount of
hours you anticipate spending and Y is the number of hours you have used so far.
Even if you over/underestimate the actual time required per task, this will be
useful for honing in the entire group's time management.

### Cadence

We'll follow a four week development cadence.

The first three of these weeks are spent on development - work on implementing
new features, which are outlined in the GitHub issues. Anytime a bug arises or
you need to implement a hacky workaround in order to get your code to work, file
it as a GitHub issue with the `bug` label. These issues represent our "technical
debt".

The last of these four weeks is when we'll repay our technical debt. This is
when you'll take the time to rewrite your hacky workarounds into something more
elegant, and deal with all the pesky little bugs that have been annoying you.

### Daily Scrum

Every weekday at 9AM PT is when we'll have our development scrum. We'll briefly
discuss open GitHub issues, work through any technical problems that depend on
multiple people, and provide an overview of what we're all working on.  Before
these meetings, have a quick look at your GitHub issues and clean up anything
that is outdated, duplicated, or out of place for whatever reason. The goal is
for the scrums to be relatively short - approximately 15 minutes.

## Best Practices

Heavily document your code, publish all of your notes into the README of the
directory you're working in, then link them in this README (the top-level
README).

This will help all of us better understand each-other's code and the
unique technical problems we've found solutions to. It'll also be a great
reference point for new developers to the project and open-source
contributors.

- Check in your working code early and often.

- This will help us avoid scenarios where there are massive breaking changes
- and everyone needs to stop development for extended periods of time to
- figure out how their code works on top of the new changes in the master
- branch. As soon as you have a new feature that is stable, create a pull
- request so that larger changes can be made incrementally.

- Frequently rebase and squash your commits.

- Since the master branch will have frequent updates, it's important to be
- proactive in rebasing your branches to the most current version of master.
- It can be a huge pain if you fall 50 commits behind and now all your code
- doesn't work. We also want the commit history to be as coherent as
- possible - frequently squash your commits so they only feature substantive
- changes (i.e get rid of all the "lint fixes" and whatnot).

## Environment Variables

You never want to have hardcoded, absolute paths in your scripts - if the paths
are specific to your machine, the code won't run on anybody else's. The way we
avoid this is through using Pipenv and the `.env` file.

For example, if you're working in our `covid-projection/model/src` directory and
are writing a Python script that needs to read or write files from/into the same
directory, you'll want to specify the path in a way that will work for anyone,
regardless of their machine. Instead of specifying the path in your script with
something like
`os.path.expanduser('~/ws/git/src/extern/covid-projection/model/src')`, it is
much better to simply add to the `.env`. You can specify this exact same path
with by running this bash command:

```bash
echo DIR_PATH=${PWD} >> .env
```

Now, when you `pipenv shell` and `echo $DIR_PATH`, an absolute path to your
working directory should be displayed.

To access environment variables in your Python scripts:

```python
import os

DIR_PATH = os.environ['DIR_PATH']
```

## Airflow

Since we have several streams of data that need to be consistently updated, we
use a tool called [Apache Airflow](https://airflow.apache.org/) to automate the
process of pulling from these streams. A tutorial for how we use Airflow with
this project can be found [here](user/lucas/airflow-study/README.md).

## Project Planning

### Creating an Issue

When creating an issue, you should always fill out all the fields:

- Assignees: You should usually assign an issue to yourself.
- Labels: Add labels to describe the issue ("bug" if something needs fixing,
  "enhancement" for a new feature, etc.)
- Projects: There is only one project currently. Assign it to the issue then click
  the dropdown to choose either "In progress" if you're working on it today or "To
  do" to leave it on the backlog. We normally want to finish things and not leave
  much hanging.
- Milestone: You should assign a milestone to each issue, often the most recent
  one.

## Google Foo

(as maintainer [@richtong](https://github.com/richtong) calls it)

If you encounter a problem and you can't find a solution,
"Google Foo" is often the solution.

Here are the steps to the Google Foo algorithm:

For the following steps, if a solution is found,
go with said solution and halt - you've solved your problem.

Steps:

1. Search for the problem directly on Google.
1. Search github directly for the problem ([here](https://github.com/search)).
1. Search on main or community website of the source of your problem.
