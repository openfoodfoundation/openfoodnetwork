#!/bin/bash

# Archive an old branch as a tagged named archive/branch-name to declutter the branch list

BRANCH_NAME=$1

git tag archive/$BRANCH_NAME $BRANCH_NAME
git checkout -q archive/$BRANCH_NAME
git branch -d $BRANCH_NAME
git checkout -q master
