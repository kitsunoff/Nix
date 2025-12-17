# Skills Guide

This is a supporting file that the skill can reference.

## Creating Skills

Skills follow Anthropic's Skills Specification v1.0:

1. Create a directory with your skill name (lowercase-with-hyphens)
2. Add a `SKILL.md` file with YAML frontmatter
3. Add supporting files in subdirectories (references/, scripts/, assets/)

## Frontmatter Requirements

```yaml
---
name: skill-name          # Required: must match directory name
description: What it does # Required: min 20 characters
license: MIT              # Optional
---
```

## Using Skills

Once the `opencode-skills` plugin is installed and skills are discovered:

```
skills_example_skill
```

This activates the skill and provides its content to the agent.
