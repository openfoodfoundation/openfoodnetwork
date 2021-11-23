---
name: Release task
about: Track the process of a new release
title: 'Release v'
labels: ''
assignees: ''

---

## Preparation on Thursday

- [ ] Merge pull requests in the [Ready To Go] column
- [ ] Merge [Transifex pull request]
- [ ] Include translations: `tx pull --force`
- [ ] [Draft new release]. Look at previous [releases] for inspiration.
- [ ] Notify [#instance-managers] of user-facing changes.

## Testing

- [ ] [Find build] of the release commit and copy it below.
- [ ] Move this issue to Test Ready and notify testers.
- [ ] Test: :warning: link to the build of the release commit https://semaphoreci.com/openfoodfoundation/openfoodnetwork-2/branches/master

## Finish on Tuesday

- [ ] Update translations unless content has been removed from config/locales/en.yml between this release draft and current master.
  <details><summary>Command line instructions</summary>
  <pre>
  git checkout master # same version as the release draft
  git fetch upstream
  git diff upstream master -- config/locales/en.yml
  tx pull --force # if no changes or only additions in the locale
  git checkout --detach # if we need to commit new translations
  git commit -a -m "Update translations"
  git tag vx.y.z # put the release number in here
  git push upstream vx.y.z
  </pre>
  </details>
- [ ] Publish and notify [#global-community]:
  > The next release is ready: https://github.com/openfoodfoundation/openfoodnetwork/releases/latest
- [ ] Deploy the new release to all managed instances.
  <details><summary>Command line instructions</summary>
  <pre>
  cd ofn-install
  git pull
  (cd ../ofn-secrets && git pull)
  ansible-playbook --limit all-prod --extra-vars "git_version=vx.y.z" playbooks/deploy.yml
  </pre>
  </details>
- [ ] Notify [#instance-managers]:
  > @instance_managers The new release has been deployed.
- [ ] Nudge next release manager

The full process is described at https://github.com/openfoodfoundation/openfoodnetwork/wiki/Releasing.

[Ready To Go]: #zenhub
[Transifex pull request]: https://github.com/openfoodfoundation/openfoodnetwork/pulls?utf8=%E2%9C%93&q=is%3Apr+is%3Aopen+head%3Atransifex
[Draft new release]: https://github.com/openfoodfoundation/openfoodnetwork/releases/new?tag=v&title=v+Code+Name&body=Congrats%0A%0ADescription%0A%0A%23%23+User+facing+changes+:eyes:%0A%0A%0A%0A%23%23+Technical+changes+:wrench:%0A%0A
[releases]: https://github.com/openfoodfoundation/openfoodnetwork/releases
[#instance-managers]: https://app.slack.com/client/T02G54U79/CG7NJ966B
[Find build]: https://semaphoreci.com/openfoodfoundation/openfoodnetwork-2/branches/master
[#global-community]: https://app.slack.com/client/T02G54U79/C59ADD8F2
