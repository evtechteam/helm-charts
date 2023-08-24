# node-red-gitops

![Version: 1.0.7](https://img.shields.io/badge/Version-1.0.7-informational?style=flat-square) ![AppVersion: 3.0.2](https://img.shields.io/badge/AppVersion-3.0.2-informational?style=flat-square)

Node-RED Helm Chart allowing GitOps workflow pulling flow files from git repositories

## Installation

### Add Helm repository

```shell
helm repo add evtechteam https://evtechteam.github.io/helm-charts
helm repo update
```

## Install Node-RED GitOps chart

Using default config:

```bash
helm install --generate-name evtechteam/node-red-gitops
```

## Configuration

The following table lists the configurable parameters of the chart and the default values.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| defaults.image | string | `"nodered/node-red"` | Image of Node-RED app |
| defaults.ingress.annotations | object | `{"forecastle.stakater.com/expose":"true","forecastle.stakater.com/icon":"https://nodered.org/about/resources/media/node-red-icon-2.png"}` | Annoations for each ingress |
| defaults.ingress.enabled | bool | `true` | Enable ingess |
| defaults.ingress.labels | string | `nil` | Labels for each ingress |
| defaults.ingress.suffix | string | `"-example.com"` | Autmated Ingress Suffix added to the release name |
| defaults.ingress.template | string | `"{{ .name }}-{{ .Release.Name }}.node-red.example.com"` | Ingress templated hostname based on instance name (overrides suffix above if set) |
| defaults.persistence | object | `{"enabled":false}` | Persistence for Node-RED flow files (not implemented) |
| defaults.projects | object | `{"base":{"branch":"main","repo":"git@bitbucket.org:user/node-red-base.git"},"enabled":true,"secrets":{"CREDENTIAL_SECRET":"change-this-secret-to-something-secure"},"url":"git@bitbucket.org:user/node-red-{{ .name }}.git"}` | Enable git based projects |
| defaults.projects.base | object | `{"branch":"main","repo":"git@bitbucket.org:user/node-red-base.git"}` | Base repo for loading common settings |
| defaults.projects.enabled | bool | `true` | Enable git based projects2 |
| defaults.projects.url | string | `"git@bitbucket.org:user/node-red-{{ .name }}.git"` | Templateable git repo for instance files |
| defaults.replicas | int | `1` | Defaults to one replica for each instance |
| defaults.safe_mode | bool | `false` |  |
| defaults.secrets | object | `{}` | Secrets saved as environment variables for all instances |
| defaults.tag | string | `"3.0.2"` |  |
| defaults.timezone | string | `"Australia/Sydney"` | Timezone |
| instances | object | `{}` | List of instances to deploy |
