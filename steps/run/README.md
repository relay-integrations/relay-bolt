# bolt-step-run

This [Bolt](https://puppet.com/products/bolt) step container runs a
[task](https://puppet.com/docs/bolt/latest/bolt_running_tasks.html) or
[plan](https://puppet.com/docs/bolt/latest/bolt_running_plans.html) against a
set of target nodes. It supports SSH and WinRM configuration in the step itself,
and the complete set of Bolt configuration via a Bolt project's `bolt.yaml` and
`inventory.yaml` files.

## Examples

```yaml
steps:
# ...
- name: bolt-run
  image: relaysh/bolt-step-run
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
