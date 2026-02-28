# Chapter 06 — Skills and Customization

NanoClaw emphasizes skills that transform your fork instead of shipping every feature in core.

## Skill flow

- User invokes skill (for example `/add-telegram`).
- Skill instructions guide repository edits.
- Resulting code is first-class source in your fork.

## Why this model

- Keeps base runtime minimal.
- Reduces dormant feature complexity in core.
- Encourages explicit, auditable changes in version control.

## Files to understand

- `.claude/skills/*/SKILL.md`
- `skills-engine/*`
- `scripts/apply-skill.ts`
