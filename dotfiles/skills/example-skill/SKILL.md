---
name: example-skill
description: An example skill demonstrating the format for opencode-skills plugin
license: MIT
---

# Example Skill

This is an example skill that demonstrates the format expected by the native OpenCode skills system.

## What This Skill Does

This skill helps you understand how to create your own skills for OpenCode.

## When to Use This Skill

Use this skill when you need to:
- Understand how to create a new skill
- Reference the skill format
- Learn about skill structure

## Instructions

When this skill is activated, you should:

1. Read the supporting documentation in `references/guide.md`
2. Follow the guidelines below

## Guidelines

- Skills are discovered automatically from `.opencode/skill/` or `~/.opencode/skill/`
- Each skill must have a `SKILL.md` file with valid YAML frontmatter
- Required frontmatter fields: `name` and `description`
- Optional frontmatter fields: `license`, `compatibility`, `metadata`
- Supporting files can be referenced with relative paths
- The skill name must match the directory name

## Skill Name Rules

The `name` must:
- Be 1-64 characters
- Be lowercase alphanumeric with single hyphen separators
- Not start or end with `-`
- Not contain consecutive `--`
- Match the directory name containing `SKILL.md`

Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

## Supporting Files

You can reference supporting files like:
- `references/guide.md` - Additional documentation
- `assets/template.html` - Files used in output
