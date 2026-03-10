<!--
SPDX-FileCopyrightText: 2025 shukon

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# dokuwiki

[Dokuwiki](https://dokuwiki.org/) is a common wiki engine that does not require a database.


## Dependencies

This service requires the following other services:

- a [Traefik](traefik.md) reverse-proxy server


## Configuration

To enable this service, add the following configuration to your `vars.yml` file and re-run the [installation](../installing.md) process:

```yaml
########################################################################
#                                                                      #
# dokuwiki                                                             #
#                                                                      #
########################################################################

dokuwiki_enabled: true

dokuwiki_hostname: mash.example.com

########################################################################
#                                                                      #
# /dokuwiki                                                            #
#                                                                      #
########################################################################
```

In the example configuration above, we configure the service to be hosted at `https://mash.example.com/`.

## Usage

You will have to open the URL `https://mash.example.com/install.php` to complete the setup, as described in the official [setup instructions](https://www.dokuwiki.org/installer).
