<!-- markdownlint-capture -->
<!-- markdownlint-disable MD041 -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [General Coding Guidelines](#general-coding-guidelines)
  - [Reducing Max Branching Depth](#reducing-max-branching-depth)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
<!-- markdownlint-restore -->

# General Coding Guidelines

A collection of explanations of best-practice coding.

## Reducing Max Branching Depth

Code that has several nested `if/else` statements and complex branching
commands can be quite difficult to read, and therefore is difficult to review
and debug. Take this short example shell script that deals with Git submodules:

```console
CFG="$(git config --file ${GITDIR}/config --name-only --get-regexp submodule)"
for f in $CFG
do
  # filter so just check urls
  if [[ $(echo $f | grep url) ]]
  then
    if ! [[ $(git config --file $GITMODULES --name-only --get-regexp $f) ]]
    then
    if ! $FORCE
    then
      log_warning dryun: deleting submodules
    else
      name = $(echo $f | cut -d. -f2)
      log_verbose "removing $name"
      git config --file ${GITDIR}/config --remove-section submodule.${name}
      rm -rf ${SOURCE_DIR}/${name}
      rm -rf ${GITDIR}/modules/${name}
      if git add ${SOURCE_DIR}/${name}
      then
        git commit -m "deleting submodule"
      else
        if ! git commit rm -r --cached $fullpath
        then exit 1
        fi
      fi
    fi
  fi
done
```

Ugly, right? This code is already hard enough to understand given the obscure
shell commands it is calling, and the deep nesting of `if/else` blocks adds
another unnecessary layer of complexity. It would be a nightmare to review or
debug this code. Using one simple trick, however, we can greatly reduce the
branching complexity.

The basic concept is anytime you're inside a loop, and you're checking for a
condition that will cause you to skip over the rest of the code in the loop and
start back up at the top with an `if/else` statement, you can probably achieve
the same thing by negating the `if` condition and using the `continue` keyword.
For example,

```console
if [[ $(echo $f | grep url) ]]
then
  ... # nested statements
```

becomes

```console
if ! [[ $(echo $f | grep url) ]]
then continue;
fi

... # the next statements are no longer nested
```

Applying this logic to the whole script, we get

```console
CFG="$(git config --file ${GITDIR}/config --name-only --get-regexp submodule)"
for f in $CFG
do
  # filter so just check urls
  if ! [[ $(echo $f | grep url) ]]
  then continue
  fi
  if [[ $(git config --file $GITMODULES --name-only --get-regexp $f) ]]
  then continue
  fi

  # submodule not found in .gitmodules so we need to delete
  name=$(echo $f | cut -d. -f2)
  if ! $FORCE
  then
    log_warning dryrun: git config --file ${GITDIR}/config --remove-section submodule.${name}
    log_warning dryrun: rm -rf ${SOURCE_DIR}/${name}
    log_warning dryrun: rm -rf ${GITDIR}/modules/${name}
    continue
  fi

  log_verbose "removing $name"
  git config --file ${GITDIR}/config --remove-section submodule.${name}
  rm -rf ${SOURCE_DIR}/${name}
  rm -rf ${GITDIR}/modules/${name}
  if git add "${SOURCE_DIR}/${name}"
  then git commit -m "deleting deprecated ${SOURCE_DIR}/${name}"; continue
  fi

  if ! git rm -r --cached $fullpath
  then
    log_warning could not delete ${SOURCE_DIR}/${name}
  fi
done
```

All of the nested `if/else` statements have been eliminated using just this one trick.
