function load_environment {
    source /var/lib/jenkins/.rvm/environments/ruby-1.9.3-p392
    if [ ! -f config/application.yml ]; then
        ln -s application.yml.example config/application.yml
    fi
}

function exit_unless_master_merged {
    if [[ `git branch -a --merged origin/$BUILDKITE_BRANCH` != *origin/master* ]]; then
	echo "This branch does not have the current master merged. Please merge master and push again."
	exit 1
    fi
}
