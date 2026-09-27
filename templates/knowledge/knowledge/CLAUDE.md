# Knowledge base schema

## Structure
- `raw/` - immutable sources. NEVER modify or delete files here.
- `wiki/` - your area. Update `index.md` and `log.md` after every operation.
- `outputs/reports/` - check reports named with a date.

## Usage
Before answering a question about the domain, architecture or decision history,
read `wiki/index.md` and open the relevant pages. Answer with links.
If the wiki has no answer, say so plainly. Do not invent.

## Page format
Frontmatter: type (source|concept|entity|synthesis|query), title, sources,
confidence (high|medium|low), updated, status (active|superseded).
Every substantive claim links to a page in `wiki/sources/`. One page = one concept or entity.

## Ingest
1. Decide what is new in the source relative to `index.md`. Nothing new -> log.md entry only.
2. Write a summary to `wiki/sources/`, update concept and entity pages.
3. Contradictions with existing pages go to a "Contradictions" section; never rewrite silently.
4. Update index.md and log.md, commit `ingest: <source name>`.

## Forbidden
Inventing facts without a source. Deleting pages - mark `status: superseded` instead.
