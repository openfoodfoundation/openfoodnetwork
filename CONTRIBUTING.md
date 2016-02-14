# Contributing

We love pull requests from everyone. Here are some instructions for
contributing code to Open Food Network. See the [developer wiki](https://github.com/openfoodfoundation/openfoodnetwork/wiki) for more information.

Fork, then clone the repo:

    git clone git@github.com:your-username/openfoodnetwork.git

Follow the instructions in README.markdown to set up your machine.

Make sure the tests pass:

    rspec spec

Make your change. Add tests for your change. Make the tests pass:

    rspec spec

Push to your fork and [submit a pull request][pr].

[pr]: https://github.com/openfoodfoundation/openfoodnetwork/compare/

At this point you're waiting on us. We may suggest some changes or
improvements or alternatives.

To increase the chance that your pull request is swiftly accepted:

* Write tests
* Use a style consistent with the rest of the codebase
* Before submitting, [rebase your work][rebase] on the current master branch

[rebase]: https://www.atlassian.com/git/tutorials/merging-vs-rebasing/workflow-walkthrough
