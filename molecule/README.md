<!--
SPDX-FileCopyrightText: 2018-2025 Slavi Pantaleev
SPDX-FileCopyrightText: 2019-2022 Aaron Raimist
SPDX-FileCopyrightText: 2019-2023 MDAD project contributors
SPDX-FileCopyrightText: 2023 QEDeD
SPDX-FileCopyrightText: 2024 Fabio Bonelli
SPDX-FileCopyrightText: 2024 Nikita Chernyi
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara
SPDX-FileCopyrightText: 2026 spatterlight

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Molecule Testing

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

## Prerequisites

To utilize Molecule you need to prepare several requirements:

- **x86** computer running one of these operating systems that make use of [systemd](https://systemd.io/):
  - **Archlinux**
  - **CentOS**, **Rocky Linux**, **AlmaLinux**, or possibly other RHEL alternatives (although your mileage may vary)
  - **Debian** (10/Buster or newer)
  - **Ubuntu** (18.04 or newer, although [20.04 may be problematic](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/ansible.md#supported-ansible-versions) if you run the Ansible playbook on it)
- `root` access on the computer which Molecule runs against
- [Ansible](http://ansible.com/) program
- [Python](https://www.python.org/)
  - Most distributions install Python by default, but some don't (e.g. Ubuntu 18.04) and require manual installation (something like `apt-get install python3`)
- [Docker](https://www.docker.com)
  - Access to Docker UNIX socket (`/var/run/docker.sock`) is required by default

## Installation

To set up the environment for using Molecule, run the command below on the terminal:

```bash
python3 -m venv ./molecule/venv
source ./molecule/venv/bin/activate
pip3 install -r ./molecule/requirements.txt
```

## Scenarios

Currently these testing scenarios are available:

DokuWiki keeps no database — its configuration and its pages are plain files below the path that this role bind-mounts into the container — and a DokuWiki which has never been through `install.php` still answers every page with HTTP 200. Both scenarios therefore seed the files that a completed installation would have left behind (from `prepare.yml`, so that `converge.yml` stays idempotent), and then check things which a wiki that was never set up cannot produce.

### `default`

Tests a standard DokuWiki installation against a pulled container image. It checks that:

- the service stays up, rather than merely reporting itself active while `Restart=always` papers over a crash loop
- the running DokuWiki reports the exact release that `dokuwiki_version` pins
- the wiki being served is the one seeded below the role's data path, rather than an unconfigured DokuWiki
- a page file below the role's data path is served over HTTP, and a page created over HTTP lands back on the host as the uid the role runs the container as — which exercises the bind mount, the uid and the directory permissions together
- an ACL-protected page is refused to an anonymous reader
- the values from `templates/env.j2` reach the PHP process, and the labels from `templates/labels.j2` reach the container

The scenario deliberately picks PHP settings that differ from the container image's own defaults, because the image happens to default to the same values the role does.

### `default-selfbuild`

Tests a standard DokuWiki installation with self-building the container image. It does not repeat what the `default` scenario already establishes, and checks what only self-building can get wrong: that the image was built rather than pulled, and that the DokuWiki release inside it is the one `dokuwiki_version` pins. The packaging repository has no per-release branches or tags, so that release is selected through a build argument whose default would otherwise install whatever release is current at build time.

## Running

By default it is configured to run the scenarios on Ubuntu 26.04.

```bash
molecule test --scenario-name default
```

You can utilize other distributions by setting one to the `MOLECULE_DISTRO` environment variable:

```bash
# Ubuntu 24.04
MOLECULE_DISTRO=ubuntu2404 molecule test --scenario-name default

# Debian 13
MOLECULE_DISTRO=debian13 molecule test --scenario-name default

# Debian 12
MOLECULE_DISTRO=debian12 molecule test --scenario-name default
```
