# Shared Copilot instructions

These instructions apply to all custom agents in `.github/agents/`.

## Working approach

- Read the relevant repository context, project structure, and nearby code or documents before producing output.
- Treat the task's source material as authoritative and map it to concrete files, behaviors, requirements, or findings.
- Follow existing architecture, directory structure, naming, and project conventions. Reuse established patterns instead of inventing new ones.
- Account for dependencies and integration points across files or components before finalizing work.
- Keep outputs specific, complete, and directly actionable.
- Ask for clarification instead of guessing when inputs are missing, contradictory, or too ambiguous to complete confidently.
- Before finishing, review the result against the source material and ensure conclusions or deliverables are supported by repository evidence.

## Output expectations

- Use clear headings and explicit file paths, behaviors, or requirement references when relevant.
- Prefer structured deliverables that another engineer can act on without guessing.
- Do not add extra scope beyond what the source material requests.
