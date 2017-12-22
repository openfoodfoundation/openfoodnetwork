# Contributing
We love pull requests from everyone. Any contribution is valuable, but there are two issue streams that we especially love people to work on:

1) Our delivery backlog, is managed via a ZenHub board (ZenHub extensions are available for most major browsers). We use a Kanban-style approach, whereby devs pick issues from the top of the backlog which has been organised according to current priorities. If you have some time and are interested in working on some issues from the backlog, please make yourself known on the [#dev](https://openfoodnetwork.slack.com/messages/C2GQ45KNU) channel on Slack and we can direct you to the most appropriate issue to pick up.

2) Our list of bugs and other self-contained issues that we consider to be a good starting point for new contributors, or devs who aren’t able to commit to seeing a whole feature through. These issues are marked with the `# good first issue` label.

## Set up

Set up your local development environment by following the appropriate guide from the `Development environment setup` section in the [developer wiki](https://github.com/openfoodfoundation/openfoodnetwork/wiki).

Fork the repo using the `Fork` button in the top-right corner of this screen. Then add the your fork as a remote on your local machine:

    cd ~/location-of-your-local-ofn-repo
    git remote add your-username https://github.com/your-username/openfoodnetwork

Fetch the latest version of `master` from the main repo:

    git fetch origin master

Create a new branch on your local machine for (based on `origin/master`):

    git checkout -b branch-name-here --no-track origin/master

If you want to run the whole test suite, we recommend using a free CI service to run your tests in parallel. Running the whole suite locally in series is likely to take > 40 minutes. [TravisCI][travis] and [SemaphoreCI][semaphore] both work great in our experience. Either way, make sure the tests pass on your new branch:

    rspec spec

## Making a change

Make your changes to the codebase. We recommend using TDD. Make changes and get the test suite back to green.

    rspec spec

Once the tests are passing you can commit your changes. See [Making a great commit][great-commit] for more tips.

    git add .
    git commit -m "Add a concise commit message describing your change here"

Push your changes to a branch on your fork:

    git push your-username branch-name-here

## Submitting a Pull Request

Use the GitHub UI to submit a [new pull request][pr] against origin/master. To increase the chances that your pull request is swiftly accepted please have a look at our guide to [[making a great pull request]].

TL;DR:
* Write tests
* Make sure the whole test suite is passing
* Keep your PR small, with a single focus
* Maintain a clean commit history
* Use a style consistent with the rest of the codebase
* Before submitting, [rebase your work][rebase] on the current master branch

From here, your pull request will progress through the [Review, Test, Merge & Deploy process][process].

[pr]: https://github.com/openfoodfoundation/openfoodnetwork/compare/
[great-pr]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Making-a-great-pull-request
[great-commit]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Making-a-great-commit
[process]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/The-process-of-review%2C-test%2C-merge-and-deploy
[rebase]: https://www.atlassian.com/git/tutorials/merging-vs-rebasing/workflow-walkthrough
[travis]: https://travis-ci.org/
[semaphore]: https://semaphoreci.com/
