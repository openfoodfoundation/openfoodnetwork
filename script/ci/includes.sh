function require_env_vars {
    for var in "$@"; do
      eval value=\$$var
      echo "$var=$value"
      if [ -z "$value" ]; then
          echo "Environment variable $var missing."
          exit 1
      fi
    done
}

function master_merged {
    if [[ `git tag -l "$BUILDKITE_BRANCH"` != '' ]]; then
	echo "'$BUILDKITE_BRANCH' is a tag."
        if [[ `git tag -l --contains origin/master "$BUILDKITE_BRANCH"` != '' ]]; then
            echo "This tag contains the current master."
            return 0
        else
            echo "This tag does not contain the current master."
            return 1
        fi
    fi
    if [[ `git branch -r --merged origin/$BUILDKITE_BRANCH` == *origin/master* ]]; then
	echo "This branch already has the current master merged."
	return 0
    fi
    return 1
}

function exit_unless_master_merged {
    if ! master_merged; then
	echo "This branch does not have the current master merged. Please merge master and push again."
	exit 1
    fi
}

function succeed_if_master_merged {
    if master_merged; then
        exit 0
    fi
}

function set_ofn_commit {
    echo "Setting commit to $1"
    buildkite-agent meta-data set "openfoodnetwork:git:commit" $1
}

function get_ofn_commit {
    OFN_COMMIT=`buildkite-agent meta-data get "openfoodnetwork:git:commit"`

    # If we don't catch this failure case, push will execute:
    # git push remote :master --force
    # Which will delete the master branch on the server

    if [[ `expr length "$OFN_COMMIT"` == 0 ]]; then
        echo 'OFN_COMMIT_NOT_FOUND'
    else
        echo $OFN_COMMIT
    fi
}

function drop_and_recreate_database {
    # Adapted from: http://stackoverflow.com/questions/12924466/capistrano-with-postgresql-error-database-is-being-accessed-by-other-users
    DB=$1
    shift
    psql postgres $@ <<EOF
REVOKE CONNECT ON DATABASE $DB FROM public;
ALTER DATABASE $DB CONNECTION LIMIT 0;
SELECT pg_terminate_backend(procpid)
FROM pg_stat_activity
WHERE procpid <> pg_backend_pid()
AND datname='$DB';
DROP DATABASE $DB;
CREATE DATABASE $DB;
EOF
}
