---
name: ship
description: Full pre-PR pipeline - cleanup, adversarial review, commit and PR.
disable-model-invocation: true
arguments: [workitem]
---
Run these steps strictly in order. Stop at the first failure and report it.

1. Invoke the `decomment` skill.
2. Invoke the `techdebt` skill.
3. Invoke the `grill` skill. If it reports any High severity issue, stop and show the list.
4. Read `~/.claude/skills/commit-push-pr/SKILL.md` and follow it with work item `$workitem`.
   Run the commands from its "Current state" section yourself first.

End with: what each step did, and the PR URL.
