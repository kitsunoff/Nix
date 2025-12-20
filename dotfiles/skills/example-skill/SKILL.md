______________________________________________________________________

## name: example-skill description: An example skill demonstrating the format for opencode-skills plugin license: MIT

# Example Skill

This is an example skill that demonstrates the format expected by the `opencode-skills` plugin.

## What This Skill Does

This skill helps you understand how to create your own skills for OpenCode.

## Instructions

When this skill is activated, you should:

1. Read the supporting documentation in `references/guide.md`
1. Use the helper script in `scripts/helper.sh` if needed
1. Follow the guidelines below

## Guidelines

- Skills are discovered automatically from `~/.config/opencode/skills/`
- Each skill must have a `SKILL.md` file with valid frontmatter
- Supporting files can be referenced with relative paths
- The base directory is provided in the skill context

## Supporting Files

You can reference supporting files like:

- `references/guide.md` - Additional documentation
- `scripts/helper.sh` - Executable scripts
- `assets/template.html` - Files used in output
