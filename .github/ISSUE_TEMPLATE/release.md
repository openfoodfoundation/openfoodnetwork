---
name: Release task
about: Track the process of a new release
title: Release v
labels: ''
assignees: ''

---

## 1. Drafting on Friday

- [ ] Merge pull requests in the [Ready To Go] column
- [ ] Include translations: `script/release/update_locales`
    - You need the [Transifex Client] installed on your local dev environement to run the script.
- [ ] Increment version number: `git push upstream HEAD:refs/tags/vX.Y.Z`
    Check for [minor or major breaking changes]
    - Major: if server changes are required (eg. provision with ofn-install)
    - Minor: larger change that is irreversible (eg. migration deleting data)
    - Patch: all others. Shortcut: `script/release/tag`
- [ ] [Draft new release]. Look at previous [releases] for inspiration.
    - Select new release tag
    - _Generate release notes_ and check to ensure all items are arranged in the right category.
- [ ] Notify [#instance-managers] of user-facing :eyes:, API :warning: and experimental :construction: changes.

## 2. Testing

- [ ] Move this issue to Test Ready.
- [ ] Notify `@testers` in [#testing].
- [ ] Test build: [Deploy to Staging] with release tag.
- [ ] Notify a deployer to deploy it

## 3. Deployment at beginning of week

- [ ] Publish and notify [#global-community] (this is automatically posted with a plugin)
- [ ] Deploy the new release to all managed instances.
  <details><summary>Command line instructions</summary>
  <pre>
  cd ofn-install
  git pull
  ansible-playbook --limit all_prod --extra-vars "git_version=vX.Y.Z" playbooks/deploy.yml
  </pre>
  </details>
- [ ] Notify [#instance-managers]:
  > @instance_managers The new release has been deployed.
- [ ] [Create issue] for next release and confirm with next release drafter in [#delivery-circle].

The full process is described at https://github.com/openfoodfoundation/openfoodnetwork/wiki/Releasing.

[Ready To Go]: https://github.com/orgs/openfoodfoundation/projects/8?filterQuery=status%3A%22Ready+to+go+%F0%9F%9A%80%22
[Transifex pull request]: https://github.com/openfoodfoundation/openfoodnetwork/pulls?utf8=%E2%9C%93&q=is%3Apr+is%3Aopen+head%3Atransifex
[Draft new release]: https://github.com/openfoodfoundation/openfoodnetwork/releases/new?title=v+Code+Name&body=Congrats%0A%0ADescription%0A%0A
[releases]: https://github.com/openfoodfoundation/openfoodnetwork/releases
[#instance-managers]: https://app.slack.com/client/T02G54U79/CG7NJ966B
[#testing]: https://openfoodnetwork.slack.com/app_redirect?channel=C02TZ6X00
[Deploy to Staging]: https://github.com/openfoodfoundation/openfoodnetwork/actions/workflows/stage.yml
[#global-community]: https://app.slack.com/client/T02G54U79/C59ADD8F2
[Create issue]: https://github.com/openfoodfoundation/openfoodnetwork/issues/new?assignees=&labels=&projects=&template=release.md&title=Release
[#delivery-circle]: https://openfoodnetwork.slack.com/archives/C01T75H6G0Z
[Transifex Client]: https://developers.transifex.com/docs/cli
[minor or major breaking changes]: https://github.com/openfoodfoundation/openfoodnetwork/pulls?q=label%3A%22breaking+change%22%2C%22major+breaking+change%22