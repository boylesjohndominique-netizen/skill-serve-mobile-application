# AI Agent Prompt Template: SkillServe Module Development

Copy this prompt for one module at a time. Replace the bracketed values before use.

```text
You are working in the SkillServe Flutter user mobile application.

Module: [PDF module number and name]
Functionality: [PDF functionality number and exact title]
Requested change: [one concise behavior or bug fix]

Read first:
- AGENT.md
- SkillServe_User_Mobile_Functionalities_Flutter.pdf
- Relevant existing files under lib/models, lib/services, lib/controllers, lib/views, and lib/routes

Scope rules:
- Implement only the functionality named above.
- Confirm it is already implemented or explicitly requested as a change to an existing module.
- Do not add deferred or not-yet-implemented PDF modules.
- Do not add admin-web functionality.
- Keep the frontend mock-data architecture; do not invent backend behavior.
- Reuse existing models, services, controllers, theme tokens, widgets, and route patterns.
- Keep API calls in services and UI state in ChangeNotifier controllers.

Before editing:
1. Identify the current screen, route, controller, service, model, and mock data used by this functionality.
2. State the current gap and the smallest safe implementation approach.
3. Check for existing tests covering the module.

Implementation requirements:
- Make the smallest correct change.
- Preserve existing navigation and mock flows.
- Handle loading, empty, validation, and failure states when applicable to the existing module.
- Avoid placeholder controls that imply a feature is implemented when it is not.
- Add or update focused widget/unit tests for the changed behavior.

Verification:
- Run flutter analyze.
- Run the focused test(s), then the relevant app sweep if layout/navigation changed.
- Report changed files, PDF requirement mapping, tests run, and any remaining limitation.
```
