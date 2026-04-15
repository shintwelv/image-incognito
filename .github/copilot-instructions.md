# Shared Copilot instructions

These instructions apply to all custom agents in `.github/agents/`.

## Shared handoff conventions

- Use predictable artifact names so agents can hand work to each other without ambiguity.
- Planner-created specifications should use the pattern `feature-[name]-planning.md` unless the user explicitly requests a different filename.
- Verification reports should use the pattern `verification-report-[feature-name]-YYYY-MM-DD.json` unless the user explicitly requests a different filename.
- When a task continues from an existing artifact, prefer an explicitly referenced file first. Otherwise, search the workspace for the most relevant matching handoff file and state which file you used.

## Working approach

- Read the relevant repository context, project structure, and nearby code or documents before producing output.
- Use Copilot workspace references such as `@workspace`, `#file`, and `#selection` when available to ground analysis, planning, implementation, and verification in repository evidence.
- Treat the task's source material as authoritative and map it to concrete files, behaviors, requirements, or findings.
- Follow existing architecture, directory structure, naming, and project conventions. Reuse established patterns instead of inventing new ones.
- Confirm the active stack from repository manifests or build files before making language, framework, or tooling assumptions.
- Account for dependencies and integration points across files or components before finalizing work.
- Keep outputs specific, complete, and directly actionable.
- Ask for clarification instead of guessing when inputs are missing, contradictory, or too ambiguous to complete confidently.
- Before finishing, review the result against the source material and ensure conclusions or deliverables are supported by repository evidence.

## Output expectations

- Use clear headings and explicit file paths, behaviors, or requirement references when relevant.
- Prefer structured deliverables that another engineer can act on without guessing.
- Do not add extra scope beyond what the source material requests.
