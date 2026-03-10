<!--
SPDX-FileCopyrightText: 2025 shukon

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Dokuwiki Ansible role

This is an [Ansible](https://www.ansible.com/) role which installs [Dokuwiki](https://dokuwiki.org) to run as a [Docker](https://www.docker.com/) container.
This role uses the [official Dokuwiki Docker image](https://hub.docker.com/r/dokuwiki/dokuwiki/), which appreciates being starred on Docker Hub.

Check [defaults/main.yml](defaults/main.yml) for the full list of supported options.
Please note that the `dokuwiki_path_prefix` option is not yet supported by this role.

For an Ansible playbook which integrates this role and makes it easier to use, see the [mash-playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).
See [setup_instructions.md](setup_instructions.md) for instructions.