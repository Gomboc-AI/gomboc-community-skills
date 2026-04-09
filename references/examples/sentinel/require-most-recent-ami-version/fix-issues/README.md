# Enforce Approved AMIs, Custom Policy

Here the goal is to fix the issue presented from Sentinel.  Because the Sentinel rule checked for 2 separate AMI images we made the rule have a variable to select that version: `enterprise_name.ubuntu_version`.  If set to "16.04" then a default 16.04 AMI is used, otherwise an "18.04" version is used.

If you want to see how the rules work:

```bash
# For the default 18.04 behavior
orl remediate -rulespace . ../workspace

# explicit 18.04 behavior
orl remediate --rulespace . --var ./vars/ubuntu_18_04 ../workspace

# 16.04 behavior
orl remediate --rulespace . --var ./vars/ubuntu_18_04 ..//workspace
```

You can use `git diff ../workspace` to see the changes.  And `git restore ../workspace` to clean it up.
