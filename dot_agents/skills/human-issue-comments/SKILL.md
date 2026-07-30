---
name: human-issue-comments
description: Write or rewrite GitHub/GitLab issue comments, pull request messages, PR review comments, maintainer replies, and follow-up notes so they sound human, concise, and useful instead of AI-generated or over-polished. Use when the user asks for comments/messages for issues or PRs, asks to make a reply sound less like AI slop, or wants a natural tone with enough technical context.
---

# Human Issue Comments

## Goal

Draft comments that sound like a competent maintainer or teammate: clear, specific, and lightly conversational. Preserve the necessary technical information, but remove filler, over-explaining, and generic AI phrasing.

## Workflow

1. Identify the comment's job:
   - ask for clarification
   - report progress
   - explain a decision
   - request changes
   - acknowledge feedback
   - close the loop after a fix
   - summarize PR scope or risk

2. Gather only the facts needed for that job:
   - concrete file, behavior, error, or user impact
   - current status or decision
   - requested next action, if any
   - uncertainty, if it matters

3. Write the comment in a natural shape:
   - Start with the point, not a preamble.
   - Use one short paragraph for simple comments.
   - Use bullets only when there are multiple distinct facts or actions.
   - Mention limits honestly: "I have not checked X yet" is better than pretending.
   - Keep thanks brief and situational.

4. Do a final "AI slop" pass:
   - Remove generic openings: "Certainly", "Great question", "Thanks for bringing this up" unless genuinely useful.
   - Remove process narration: "I took a look and analyzed..." unless the investigation path matters.
   - Remove inflated wording: "comprehensive", "robust", "seamless", "leverage", "ensure" when plain words work.
   - Remove redundant reassurance: "This should now work as expected" if the test/result already says that.
   - Prefer exact verbs: "fixed", "renamed", "split", "left unchanged", "needs".

## Tone Rules

- Sound like one person writing to another, not a press release.
- Be direct, but not curt.
- Keep contractions when they fit the language and project tone.
- Use the same language as the target thread unless the user asks otherwise.
- Do not invent certainty, test results, root causes, or consensus.
- Do not over-apologize. Say what changed or what is needed.
- Do not decorate with emojis unless the project already uses them.

## Useful Shapes

### Asking for Details

```text
I cannot reproduce this from the current steps. Can you add the exact input and the version you are running? A short log around the failure would also help.
```

### Progress Update

```text
I found the issue: the fallback path was still using the old field name. I have a fix in progress and will add a small regression test before pushing it.
```

### PR Review Comment

```text
This changes the behavior for empty values as well. Was that intentional? If not, I would keep the old empty-value path and only apply the new logic after validation succeeds.
```

### Change Request

```text
Can you split this into two commits? The parser change and the UI cleanup are independent, and reviewing them separately would make the behavior change easier to verify.
```

### Closing The Loop

```text
Fixed in the latest push. I also added a regression test for the missing-header case, since that was the part that failed here.
```

## When Rewriting

Preserve the author's intent and facts. Tighten the message by cutting:

- duplicated context
- generic praise
- caveats that do not affect the reader
- long explanations of obvious code
- passive constructions that hide the action

Return only the suggested comment unless the user asks for rationale or variants.
