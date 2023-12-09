---
name: Release task
about: Track the process of a new release
title: Release v
labels: ''
assignees: ''

---

## 1. Preparation on Thursday

- [ ] Merge pull requests in the [Ready To Go] column
- [ ] Include translations: `script/release/update_locales`
- [ ] Increment version number: `git push upstream HEAD:refs/tags/vX.Y.Z`
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

## 3. Finish on Tuesday

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
- [ ] Nudge next release manager

The full process is described at https://github.com/openfoodfoundation/openfoodnetwork/wiki/Releasing.

[Ready To Go]: #zenhub
[Transifex pull request]: https://github.com/openfoodfoundation/openfoodnetwork/pulls?utf8=%E2%9C%93&q=is%3Apr+is%3Aopen+head%3Atransifex
[Draft new release]: https://github.com/openfoodfoundation/openfoodnetwork/releases/new?tag=v&title=v+Code+Name&body=Congrats%0A%0ADescription%0A%0A
[releases]: https://github.com/openfoodfoundation/openfoodnetwork/releases
[#instance-managers]: https://app.slack.com/client/T02G54U79/CG7NJ966B
[#testing]: https://openfoodnetwork.slack.com/app_redirect?channel=C02TZ6X00
[Deploy to Staging]: https://github.com/openfoodfoundation/openfoodnetwork/actions/workflows/stage.yml
[#global-community]: https://app.slack.com/client/T02G54U79/C59ADD8F2
