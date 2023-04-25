# Contributing
We love pull requests from everyone. Any contribution is valuable!

If you have some time and are interested in working on some issues please make yourself known on the [#dev][slack-dev] channel on Slack.

We have curated all issues we consider to be a good starting point for new members of the community within the [Welcome New Developers project board][welcome-dev]. Have a look and pick the one you would prefer working on!

## Set up

Please follow the [GETTING_STARTED](GETTING_STARTED.md) guide to set up your local dev environment.

This guide assumes that the git remote name of the main repo is `upstream` and that your fork is named `origin`.

Create a new branch on your local machine to make your changes against (based on `upstream/master`):

    git checkout -b branch-name-here --no-track upstream/master

You might need to update or install missing gems:

    bundle install

Also, there might be missing dependencies, after pulling a particular branch. To update dependencies, run:

    yarn install

If you want to run the whole test suite, we recommend using a free CI service to run your tests in parallel. Running the whole suite locally in series is likely to take > 40 minutes. [TravisCI][travis] and [SemaphoreCI][semaphore] both work great in our experience. Either way, make sure the tests pass on your new branch:

    bundle exec rspec spec

## Internationalisation (i18n)

The locale `en` is maintained in the source code, but other locales are managed at [Transifex][ofn-transifex]. Read more about [internationalisation][i18n] in the developer wiki.

## Making a change

Make your changes to the codebase. We recommend using TDD. Add a test, make changes and get the test suite back to green.

    bundle exec rspec spec

Once the tests are passing you can commit your changes. See [Making a great commit][great-commit] for more tips.

    git add .
    git commit -m "Add a concise commit message describing your change here"

Push your changes to a branch on your fork:

    git push origin branch-name-here

## Submitting a Pull Request

Use the GitHub UI to submit a [new pull request][pr] against upstream/master. To increase the chances that your pull request is swiftly accepted please have a look at our guide to [making a great pull request][great-pr]. 

TL;DR:
* Write tests
* Make sure the whole test suite is passing
* Keep your PR small, with a single focus
* Maintain a clean commit history
* Use a style consistent with the rest of the codebase
* Before submitting, [rebase your work][rebase] on the current master branch
* After submitting, be sure to check the [CI test results](ci). Click on a ❌ result to view the logged results and investigate.

From here, your pull request will progress through the [Review, Test, Merge & Deploy process][process].

[pr]: https://github.com/openfoodfoundation/openfoodnetwork/compare/
[great-pr]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Making-a-great-pull-request
[great-commit]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Making-a-great-commit
[process]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/The-process-of-review%2C-test%2C-merge-and-deploy
[rebase]: https://www.atlassian.com/git/tutorials/merging-vs-rebasing/workflow-walkthrough
[travis]: https://travis-ci.org/
[semaphore]: https://semaphoreci.com/
[slack-dev]: https://openfoodnetwork.slack.com/messages/C2GQ45KNU
[ofn-transifex]: https://www.transifex.com/open-food-foundation/open-food-network/
[i18n]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Internationalisation-%28i18n%29
[welcome-dev]: https://github.com/orgs/openfoodfoundation/projects/5
[ci]: https://github.com/openfoodfoundation/openfoodnetwork/wiki/Continuous-Integration
