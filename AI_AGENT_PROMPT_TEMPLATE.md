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
- api-docs/README.md
- api-docs/MODULES.md
- Relevant api-docs/modules/*.md files for this module
- Relevant existing files under lib/models, lib/services, lib/controllers, lib/views, and lib/routes

Scope rules:
- Implement only the functionality named above.
- Confirm it is already implemented or explicitly requested as a change to an existing module.
- Do not add deferred or not-yet-implemented PDF modules.
- Do not add admin-web functionality.
- Keep the frontend mock-data architecture; do not invent backend behavior.
- Respect the current `AppConfig.useMockData`/`USE_MOCK_DATA` configuration; do not silently switch live and mock modes.
- Use only endpoints documented in `api-docs`; use `/api/client/v1/*` for mobile customer flows.
- Put live Dio calls in services behind `if (!AppConfig.useMockData)` and keep mock branches working.
- Use `ApiClient` and `TokenStorage` for bearer authentication; never store passwords.
- Handle documented 401/403/422 responses without putting API calls in widgets.
- If no client endpoint is documented for a requested behavior, do not invent one; leave an explicit service-layer limitation.
- Reuse existing models, services, controllers, theme tokens, widgets, and route patterns.
- Keep API calls in services and UI state in ChangeNotifier controllers.

Before editing:
1. Identify the current screen, route, controller, service, model, and mock data used by this functionality.
2. State the current gap and the smallest safe implementation approach.
3. Check for existing tests covering the module.
4. Map every live endpoint to its exact documented method, path, request fields, response envelope, and auth requirement.

Implementation requirements:
- Make the smallest correct change.
- Preserve existing navigation and mock flows.
- Handle loading, empty, validation, and failure states when applicable to the existing module.
- Avoid placeholder controls that imply a feature is implemented when it is not.
- Add an endpoint comment containing the exact documented route and explain any mock-only limitation.
- Add or update focused widget/unit tests for the changed behavior.

Verification:
- Run flutter analyze.
- Run the focused test(s), then the relevant app sweep if layout/navigation changed.
- Report changed files, PDF requirement mapping, tests run, and any remaining limitation.
```
