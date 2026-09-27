---
name: techdebt
description: Find duplication, dead code and leftovers in the current branch. Invoke only when the user or another skill explicitly asks for it.
---
Review `git diff main...HEAD`. Find duplicated logic, dead code, leftover debug output,
unused usings and TODOs added in this branch. Fix only safe mechanical issues;
list the rest for me. End with: fixed | left for review.
