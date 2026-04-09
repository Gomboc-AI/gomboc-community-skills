# Enforce Approved AMIs - Custom Policies

This is an existing Sentinel policy that makes sure that AMIs use an `aws_ami` data element, and that data element references a known good pattern, and has `most_recent` set to true.  We created 2 examples from this.

1. [Audit Only](./audit-only/README.md) - Acts like sentinel in just saying what is wrong
2. [Fix Issues](./fix-issues/README.md) - Fixes the issues automatically.

If you just want to see how the rules work:

```bash
# Check the audit
cd audit-only
orl remediate --rulespace . ../workspace; echo $?

# Now check the fix
cd ../fix-issues
orl remediate --rulespace . ../workspace
git diff ../workspace     # see what changed
git restore ../workspace  # revert the changes
```

> [!NOTE]
> You can use `remediate -d` to do a dry-run and print the updated workspace files to the screen instead of writing them to disk.  It is harder to see the diffs, but prevents you from accidentally committing changes.

## Sentinel vs ORL

It is important to know that the [Sentinel Policy](./require-most-recent-AMI-version.sentinel) is checking the Terraform State, and therefore has access to the fully rendered state objects and relationships.  ORL only works on the source code thus the way you think about rules is slightly different.  With ORL you are using code patterns to try to catch and remediate issues.

ORL looks for patterns in code and then iterates through those findings applying logic and/or remediations.  Therefore an ORL rule just defines the patterns and fixes; not the implementation.  However, there is generally no single "right" way to develop ORL fixes.  It really depends on the types of behaviors you want to express, and how widely applicable you want the rule to be.

## Understanding the Process

The process we followed was the same [Building Rules](../../docs/build_rules.md) process we follow for all rule builds.

### Create a "Workspace"

First, we generated a workspace (in [workspace](./workspace/)) that demonstrated the edge cases to be remediated.  These aren't fully valid IaC files.  Instead they represent realistic edge cases that we use to test that the rules patches (or do not patch) as expected.  They are:

- `valid.tf` - an example that shouldn't be touched by ORL
- `not_using_data.tf` - an example of an instance not using a data element for its `ami` attribute
- `missing_ami.tf` - an example of an instance that isn't defining the `ami` element
- `invalid_data_aws_ami.tf` - various examples of invalid `data.aws_ami` resources
  - `missing_most_recent` is missing the `most_recent` flag
  - `invalid_most_recent` sets the flag to `false`
  - `invalid_ami_pattern` uses an unapproved name pattern
  - `invalid_ami_owner` uses an image from an unapproved owner
  - `no_name_filter` doesn't have a name filter

### Audit

With the workspace created we can create an audit rule that behaves similarly to Sentinel in that it will only print the details.  This was done in [./audit-only](./audit-only/README.md).  It serves as the basis for later generating fix rules.

The `test.orl` ensures the audit work as we want them to.  Since the audit doesn't modify the workspace we check the ORL report output against expectations.

`orl language terraform` is used to see what helpers are available to be used in rules.  Since data objects don't yet have templates `orl walk workspace ./workspace` is used to see how ORL parses the workspace; which is then used to create the audit patterns.  Tree Sitter's [Query Syntax](https://tree-sitter.github.io/tree-sitter/using-parsers/queries/1-syntax.html) is used for raw traversal.

All the rules are defined in `rules.orl`.

### Develop the Fix

Developing the fix is a bit more involved in that you have to decide what the correct fix is given each scenario.  The more assumptions you make the simpler the rule is, but the more likely it is to catch unexpected edge cases.  For our purposes, we assume the ami IDs have to be one of the pre-approved ones based on Ubuntu 16.04 or 18.04.

#### Set the Expectations

Once the workspace is defined we generate the expected workspace(s) that have the fixes present.  Because the example showed the use of 2 versions of Ubuntu we provided separate expectations for each:

- `expected_workspace_with_defaults` includes the behaviors if no version is provided or if the version is 18.04
- `expected_workspace_for_16_04` is for when 16.04 is chosen

Because a choice can be made we use the [variable](../../docs/orl_language.md#variables) `enterprise.ubuntu_version` to drive behavior.

#### Automated testing (`test.orl`)

Once the workspaces are defined we created the `test.orl` that helps run the scenarios in an automated fashion while we build our rules.  The test cases are

- Works when no version is specified - checks against `expected_workspace_with_defaults`
- Works when version is 16.04 - loads the variables in `vars/ubuntu_16_04` and checks against `expected_workspace_for_16_04`
- Works when version is 18.04 - loads the variables in `vars/ubuntu_18_04` and checks against `expected_workspace_with_defaults`
- Errors correctly when version is invalid - loads the variable in `vars/invalid` and checks the error in the report

The test cases are run en mass via `orl test .`.

##### Manual testing

> [!PRO TIP]
> `orl test <directory>` will print the `orl remediate ...` command that is needed to manually patch the test cases and print the results.  This is usually the easiest way to get the command line for debugging tests and running tests manually.

If you want to run tests manually use `orl remediate -d <workspace directory>`.  The `-d` argument is a dry run and instead of changing the files on disk it will print the updated files to the console.  Other useful arguments are:

- `--rulespace <directory>` - Load the rules to run.
- `--var <directory>` - Loads variables files and makes them available to rules.
- `-v` - increase the level of debugging.  Add more `v`s for more debugging.

For example:

```bash
cd fix-issues
orl remediate -d --rulespace . --var ./vars ../workspace
```

#### Building the Rule

With the test cases defined the following [Rulesets](../../docs/orl_language.md#ruleset) were built:

- `aws_instance-ami-requires-data-reference.orl` - executed first to handle `aws_instance`.  It is made up of two rules:
  - Update aws_instance if missing ami - Updates instances that don't define an ami by creating a data item and using in the `ami` attribute.  The created data item is checked and fixed by later rules.
  - Update aws_instance if ami is not using data - Similar to the first, but updates the existing attribute instead of creating a new one
- `data-aws_ami-owners-is-valid.orl` - executed second, it makes sure the owner is valid in the `data.aws_ami` objects.  It is made up of two rules:
  - Update aws_ami if owner is missing - Adds `owners` if it is missing
  - Update aws_ami if owner is wrong - Fixes the value
- `data-aws_ami_most_recent-is-true.orl` - executed third, it makes sure `most_recent` is `true`.  It is made up of two rules:
  - Update aws_ami if most_recent is missing - Adds `most_recent` if it is missing
  - Update aws_ami if most_recent is not true - If it is false then switch it to true
- `data-aws_ami-filter-name-is-valid.orl` - executed fourth, it handles updating the `filter` based on an optional variable `enterprise_name.ubuntu_version`.  It is made up of two rules:
  - Update aws_ami if name filter is missing - Adds one if it is missing
  - Update aws_ami fix name filter - Update the name to an approved pattern if it is wrong

#### Publish the rules

You can publish the rules in one of two ways:

1. Copy the files into a target repo and sym-link it into directory that contains terraform you want remediated.
2. Use `orl rules push` with your Gomboc PAT to push the rule to your account.
  1. Later you can use `orl rules pull --query '(contains $.name "enterprise_name")'` to pull the rules and remediate a directory.
