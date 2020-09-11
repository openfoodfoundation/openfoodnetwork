---
name: Release task
about: Track the process of a new release
title: 'Release v'
labels: ''
assignees: ''

---

Steps: 

- [ ] Include translations: `tx pull --force`
- [ ] [Draft new release]
- [ ] Notify #instance-managers of user-facing changes.
- [ ] Test: https://semaphoreci.com/openfoodfoundation/openfoodnetwork-2/branches/master <!-- replace the URL -->
- [ ] Update translations if necessary
- [ ] Publish and notify #global-community
- [ ] Deploy and notify #instance-managers
- [ ] Nudge next release manager

The full process is described at https://github.com/openfoodfoundation/openfoodnetwork/wiki/Releasing.

[Draft new release]: https://github.com/openfoodfoundation/openfoodnetwork/releases/new?tag=v&title=v+Code+Name&body=Congrats%0A%0ADescription%0A%0A%23%23+User+facing+changes+:eyes:%0A%0A%0A%0A%23%23+Technical+changes+:wrench:%0A%0A
