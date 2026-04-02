# ORL Quick Reference
ORL is a system for auditing and remediating infrastructure as code. It lets you write rules which audit the code, and subsequently remediate that code to fix violations deterministically.

> **Docker invocation**: ORL is run via Docker. All commands use: `docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]`

## Audit Queries
Audit queries are written using tree-sitter queries. For more information on the tree-sitter query language, see [tree-sitter.md](tree-sitter.md).

Audit queries use tree-sitter queries to accomplish two objectives:
1. Use predicates to filter the captures, denoting whether or not the capture is a violation of the rule. We are seeking the inverse of the rule's remediation - that is, an audit "passes" if the rule's remediation does NOT need to be applied.
2. Use capture groups to identify the nodes that we will later use during the remediation step.

## Remediations

A remediation is composed of the following fields:
- `command` (required, string) - is the command to execute, which is detailed below
- `value` (string) - is the value to use with the command.
- `skip` (string) - is an additional logic query that can be used to determine if the command should be skipped
- `path` (string) - is the name of the capture group node that the command should execute against.  This is the anchor point for the command.
- `flags` (list) - are any flags that can modify the behavior of the command. Each flag is a key-value pair in the format `["key", "value"]`. There are both global flags (can be used by any command), and command-specific flags (can only be used by the command they are defined for).

The command instructs ORL to take an action, using the value and path. A command may be skipped provided a condition is met within the `skip` field. Flags influence the behavior of the command - think of them like arguments to a command line tool. The path denotes which node (a capture group from the audit query) the command should execute against.

The capture groups produced by audit queries can be used during the remediation step, in various fields. Their access pattern is simply `{{ $.<capture group key> }}`. You can use them in the `value` field and the `skip` field.

> The path field is a notable exception - here, you simple use the plaintext string name of the capture group node you want to target/operate on, rather than the access pattern.

### Available Commands
These are the available remediation commands at this time. Each command may have its own specific flags that can be used to modify its behavior.

#### `insert_after`
Insert on the next line after the last captured node with name `path`.

Flags:
- `before_newline` - insert directly after the node, instead of on the next line.

#### `insert_before`
Insert the value into the file directly before the first captured node with name `path`.

#### `replace`
Replace the entire the first captured node's content with `value` or only some number of patterned substrings.

Flags:
- `pattern` - A substring match to replace instead of the entire node
- `count` (default "-1") - The number of substrings to replace (left to right). -1 = all, 0 = none.

#### `remove`
This will remove the first captured node defined in `path` plus everything before it until the newline.

### Globally-available Flags
The following are available for every remediation command:
- `indent` - Prepends the specified indentation to all lines of the `value`. Use this instead of including spaces/tabs directly in the value string, as inline whitespace can be stripped or mishandled within the `value` field.
- `prefix` - Prepends the value once to the beginning of the `value`
- `suffix` - Appends the value once to the end of the `value`

# Templating
ORL also supports templates. You may use them in the following fields:
- `audit`
- `remediation.skip`
- `remediation.value`
- `skip_finding`

## Finding Skip vs Remediation Skip
It is important to understand the difference between `skip_finding` and `remediation.skip`.

- `skip_finding`: This logic is evaluated *after* the audit query finds a match, but *before* any remediations are considered. If this evaluates to `true`, the finding is effectively ignored - it is not counted as a violation, and NO remediations are run. This is the preferred way to filter out "false positives" based on logic (e.g. `vars.config.env == 'dev'`) rather than making the Tree-Sitter query overly complex.
- `remediation.skip`: This logic is evaluated for a *specific* remediation command. If `true`, only that single command is skipped, but other commands for the finding will still run. Use this for conditional fixes (e.g. "only add this attribute if it doesn't already exist").

The `audit`, and `remediation.value` use pre-pass inline templating.  An inline template is denoted by `{{ }}` and fully expanded and converted to a string values.  Once all inline templates are fully expanded and the value is a single string is it used.

The `remediation.skip` field evaluates as a complete template, which is then converted to a boolean value, as explained below.  If `true` then the remediation step is skipped.

The `skip_finding` field works exactly like `remediation.skip` - it evaluates as a complete template to a boolean.

## `Expr` Language
**Expr** is an expression language for Go which is evaluated within the `{{ }}` blocks.  It is the same language that drives Argo Workflow's templating.  There are a [set of built-in functions](https://expr-lang.org/docs/language-definition) for working with various data structures.  And `{{ }}` blocks can span multiple lines.

### Handling Complex Templates
Templates can be very complex which can have strange results in the real world.  Here are some suggestions for handling complex templates:

1. Use the audit query's inline logic to reduce the collections and findings as much as possible
2. Don't rely on template logic `remediation.value`, instead use multiple steps and `remediation.skip` to skip the unwanted ones.
3. Use the `audit` remediation command to print all the stages of the template evaluation
    1. This will cause a remediation failure to be printed in the final report.

## Access Patterns
Within templates, data can be as follows, where `item` denotes an item context:
- Path: `<item>.<path>[.<path>]` - The path element cannot contain special characters, but can be either a key or an index (i.e., `item.0`).  `?.` can be used to return nil (instead of error) if the path element is missing (i.e., `this.that?.foo` will still work in `that` is missing).
- Index: `<item>[<index>]` - Index is number.  This will error if the index is out of bounds
- Key: `<item>["<key>"]` - Key can be any string.  If the key is missing then `nil` is returned.

### Items
Item contexts that currently exist:
- `$` - each named capture group from the audit is available.

## Remediation Skip
The remediation skip conditional is a special case in that it is evaluated and then converted to a truthy value, which we document below:

| Type   | Value                             | Truthy | Comment                                                                                   |
| ------ | --------------------------------- | ------ | ----------------------------------------------------------------------------------------- |
| Array  | `[]`                              | false  | Empty array is false                                                                      |
| Bool   | `false`                           | false  | Unquoted false is false                                                                   |
| Map    | `{}`                              | false  | Empty map is false                                                                        |
| Nil    | `nil`                             | false  | Nil is false                                                                              |
| Number | `0`                               | false  | 0 is false                                                                                |
| String | `""`, `"0"`, `"false"`, `"<nil>"` | false  | Empty string is false.  Note, use use "<nil>" because that is the value of `string(nil)`. |
| Array  | `[1,2,3]`                         | true   | Non-empty array is true                                                                   |
| Bool   | `true`                            | true   | Unquoted true is true                                                                     |
| Map    | `{1: false}`                      | true   | Non-empty map is true                                                                     |
| Number | `-1`                              | true   | any value not 0 is true                                                                   |
| String | `"true"`, `"this"`                | true   | Any non-empty string is true                                                              |
