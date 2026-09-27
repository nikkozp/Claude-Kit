---
name: decomment
description: Remove low-value comments from the current diff. Invoke only when the user or another skill explicitly asks for it.
allowed-tools: Bash(git diff *) Bash(git ls-files *) Read Edit
---
Review `git diff HEAD` and new untracked files. Remove comments that restate the code,
narrate the change, reference the task or conversation, or contain commented-out code;
remove XML docs on non-public members. Keep comments explaining a non-obvious reason,
constraint or workaround, issue links, and public API docs of library projects.
Do not change any code behavior. Report how many comments were removed and why others were kept.
