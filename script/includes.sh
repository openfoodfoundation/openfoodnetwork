function exit_unless_master_merged {
    if [[ `git branch -a --merged $BUILDKITE_BRANCH` != *origin/master* ]]; then
	echo "This branch does not have the current master merged. Please merge master and push again."
	exit 1
    fi
}
