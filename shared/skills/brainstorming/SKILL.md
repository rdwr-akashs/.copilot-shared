---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Activation Rule

**Triggers:**
- User asks to "build", "create", "add", or "implement" a new feature or component
- User describes a vague idea that needs shaping before code
- Requirements are ambiguous or span multiple modules
- A design decision affects driver-api contracts or multiple DefensePro versions

> **Override Directive:** This skill overrides default behavior when its conditions are met. Do NOT jump to implementation — brainstorm first.

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria
- For this project: identify which modules are affected (service, driver-api, drivers, feeds, util, ui)

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why
- Consider multi-version driver impact for any driver-api changes

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: module boundaries, API contracts, data flow, JPA entities, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit the design document to git

**Implementation (if continuing):**
- Ask: "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Module awareness** - Always identify which Maven modules are affected
- **Driver version impact** - Consider all active DefensePro driver versions

## Agent Integration

| Agent | Usage |
|-------|-------|
| **Architect (PEplan)** | Primary user — drives all brainstorming sessions before writing plans |
| **Developer** | Triggers brainstorming when requirements are unclear during implementation |
| **Debugger** | Not typically used |
| **Reviewer** | References brainstorming output to validate design intent vs implementation |

## Decision Heuristics

- **Use brainstorming** when the task touches 2+ modules or has unclear scope
- **Skip brainstorming** for single-file bug fixes with clear root cause
- **Combine with `writing-plans`** after brainstorming produces a validated design
- Example: "Add a new protection profile type" → brainstorm (multi-driver impact)
- Example: "Fix NPE in PolicyTemplateService line 42" → skip, use `systematic-debugging`
- Example: "Add export functionality for templates" → brainstorm (unclear scope, UI+backend)

## Quick Start

1. Read project state (`activeContext.md`, recent commits)
2. Ask ONE question to clarify intent
3. Propose 2-3 approaches with trade-offs
4. Present design in 200-300 word sections, validate each
5. Save to `docs/plans/YYYY-MM-DD-<topic>-design.md`

## Prompt Template

```
I need to brainstorm a design for: [feature description].
Affected modules: [service/driver-api/drivers/ui/feeds].
Use the brainstorming skill to explore approaches before implementation.
```

## Performance Guidelines

- Limit brainstorming to 3-5 questions max before proposing approaches
- Present at most 3 alternatives — more causes analysis paralysis
- Cap design sections at 300 words — validate incrementally, don't dump

## Inter-Skill References

- **After brainstorming** → `writing-plans` to create implementation plan
- **For workspace isolation** → `using-git-worktrees` before implementation
- **For execution** → `executing-plans` or `subagent-driven-development`
