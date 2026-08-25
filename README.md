<!--
SPDX-FileCopyrightText: 2023 Slavi Pantaleev
SPDX-FileCopyrightText: 2025 shukon
SPDX-FileCopyrightText: 2025, 2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# DokuWiki Ansible role

This is an [Ansible](https://www.ansible.com/) role which installs [DokuWiki](https://dokuwiki.org/) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

This role *implicitly* depends on:

- [`com.devture.ansible.role.playbook_help`](https://github.com/devture/com.devture.ansible.role.playbook_help)
- [`com.devture.ansible.role.systemd_docker_base`](https://github.com/devture/com.devture.ansible.role.systemd_docker_base)

Check [`defaults/main.yml`](defaults/main.yml) for the full list of supported options. Refer to [this page](docs/configuring-dokuwiki.md) for details about setting up the service with this role.

💡 For an Ansible playbook which integrates this role and makes it easier to use, see the [Mother-of-All-Self-Hosting Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

## Development

### pre-commit

You can optionally install a Git pre-commit hook (via [mise](https://mise.jdx.dev/) + [prek](https://prek.j178.dev/)) that runs formatting and linting checks before each commit. See [`.pre-commit-config.yaml`](./.pre-commit-config.yaml) for which hooks are to be executed.

To install the hook, run the [`just`](https://github.com/casey/just) command below:

```sh
just prek-install-git-pre-commit-hook
```

### Molecule

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

Refer to [this page](./molecule/README.md) for details about how to utilize it.

### Releases

Releases are tagged automatically. Every push to `main` runs [`bin/compute-next-tag.sh`](./bin/compute-next-tag.sh), which derives the tag from [`defaults/main.yml`](defaults/main.yml) and the tags that already exist, rather than from commit messages — so the result does not depend on the order in which changes get merged, and any change that affects the role releases itself.

Tags look like `v<DokuWiki version>-<release>`, for example `v2025-05-14b-4`. DokuWiki names its releases after their release date and its hotfix releases by appending a letter to it, so `2026-07-14` and `2026-07-14a` are two different releases, each with a release counter of its own.

[`bin/test-compute-next-tag.sh`](./bin/test-compute-next-tag.sh) exercises the computation against throwaway repositories; it runs as a prek hook whenever the script or `defaults/main.yml` changes.
