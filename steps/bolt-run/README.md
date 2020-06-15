# bolt-run

This [Bolt](https://puppet.com/products/bolt) step container runs a
[task](https://puppet.com/docs/bolt/latest/bolt_running_tasks.html) or
[plan](https://puppet.com/docs/bolt/latest/bolt_running_plans.html) against a
set of target nodes. It supports SSH and WinRM configuration in the step itself,
and the complete set of Bolt configuration via a Bolt project's `bolt.yaml` and
`inventory.yaml` files.

## Specifications

| Setting | Child setting | Data type | Description | Default | Required |
|---------|---------------|-----------|-------------|---------|----------|
| `type` || string | The type of Bolt action to perform, one of `task` or `plan`. | None | True |
| `name` || string | The name of the Bolt task or plan to run. | None | True |
| `parameters` || mapping | The task- or plan-specific parameter data to use for this run. | None | False |
| `projectDir` || string | When the `git` setting is specified, the relative directory within the Git repository to use as the Bolt project. | `.` | False |
| `modulePaths` || array | A list of additional directories outside of the project directory to add to the Bolt module path. | None | False |
| `installModules` || boolean | Download and install modules listed in a `Puppetfile`. | `false` | False |
| `transport` || mapping | The default transport to use when connecting to the target nodes. | None | False |
|| `type` | string | The transport type, one of `ssh` or `winrm`. | None | False |
|| `user` | string | The username to use to connect. | None | False |
|| `password` | string | The password to use to connect. | None | False |
|| `privateKey` | string | The name of a key in the `credentials` setting to use as the default SSH private key. | None | False |
|| `useSSL` | boolean | If using the WinRM transport, whether to use SSL to connect. | `true` | False |
|| `verifyHost` | boolean | Whether to verify host integrity when connecting to remote nodes. | `true` | False |
| `targets` || string or array | The list of target nodes to connect to, either in the same format as Bolt expects (a comma-separated string), or as a list. | None | False |
| `credentials` || mapping | A map of sensitive credential data encoded using Base64. | None | False |
| `git` || mapping | A map of git configuration. If you're using HTTPS, only `name` and `repository` are required. | None | False |
|| `ssh_key` | string | The SSH key to use when cloning the Git repository. You can pass the key to Nebula as a secret. See the example below. | None | False |
|| `known_hosts` | string | SSH known hosts file. | None | False |
|| `name` | string | A directory name for the Git clone. | None | False |
|| `branch` | string | The Git branch to clone. | `master` | False |
|| `repository` | string | The Git repository URL. | None | False |

> **Note**: The value you set for a secret must be a string. If you have
> multiple key-value pairs to pass into the secret, or your secret is the
> contents of a file, you must encode the values using base64 encoding, and use
> the encoded string as the secret value.

## Examples

```yaml
steps:
# ...
- name: bolt-run
  image: projectnebula/bolt-run
  spec:
    type: task
    name: facts::bash
    targets:
    - a.example.com
    - b.example.com
    credentials:
      id_rsa:
        $type: Secret
        name: id_rsa
    transport:
      type: ssh
      user: ubuntu
      privateKey: id_rsa
```
