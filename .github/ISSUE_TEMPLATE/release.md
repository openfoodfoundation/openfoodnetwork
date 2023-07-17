---
name: Release task
about: Track the process of a new release
title: Release v
labels: ''
assignees: ''

---

## 1. Preparation on Thursday

- [ ] Merge pull requests in the [Ready To Go] column
- [ ] Include translations: `tx pull --force`
- [ ] [Draft new release]. Look at previous [releases] for inspiration.
- [ ] Notify [#instance-managers] of user-facing changes.

## 2. Testing

- [ ] [Find build] of the release commit and copy it below.
- [ ] Move this issue to Test Ready.
- [ ] Notify `@testers` in [#testing].
- [ ] Test build: <!-- paste build link here, e.g. https://semaphore...builds/1234 -->

## 3. Finish on Tuesday

- [ ] Publish and notify [#global-community] (this is automatically posted with a plugin)
- [ ] Deploy the new release to all managed instances.
  <details><summary>Command line instructions</summary>
  <pre>
  cd ofn-install
  git pull
  ansible-playbook --limit all-prod --extra-vars "git_version=vx.y.z" playbooks/deploy.yml
  </pre>
  </details>
- [ ] Notify [#instance-managers]:
  > @instance_managers The new release has been deployed.
- [ ] Nudge next release manager

The full process is described at https://github.com/openfoodfoundation/openfoodnetwork/wiki/Releasing.

[Ready To Go]: #zenhub
[Transifex pull request]: https://github.com/openfoodfoundation/openfoodnetwork/pulls?utf8=%E2%9C%93&q=is%3Apr+is%3Aopen+head%3Atransifex
[Draft new release]: https://github.com/openfoodfoundation/openfoodnetwork/releases/new?tag=v&title=v+Code+Name&body=Congrats%0A%0ADescription%0A%0A%23%23+User+facing+changes+:eyes:%0A%0A%0A%23%23%23+Experimental+features+for+testing+:sunglasses:%0A%0A%0A%23%23+Technical+changes+:wrench:%0A%0A
[releases]: https://github.com/openfoodfoundation/openfoodnetwork/releases
[#instance-managers]: https://app.slack.com/client/T02G54U79/CG7NJ966B
[#testing]: https://openfoodnetwork.slack.com/app_redirect?channel=C02TZ6X00
[Find build]: https://semaphoreci.com/openfoodfoundation/openfoodnetwork-2/branches/master
[#global-community]: https://app.slack.com/client/T02G54U79/C59ADD8F2
