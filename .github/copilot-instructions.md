# Issuer Frontend Repo Guidance

- Use GPT-5.4 by default for standards-sensitive work in this repo.
- Treat `project-docs/docs/EIDAS_ARF_Implementation_Brief.md` and `project-docs/docs/AI_Working_Agreement.md` as mandatory constraints.
- This repo owns the issuer web frontend and supporting built assets for local issuance journeys.
- Keep changes aligned with issuer metadata and backend contracts.
- When frontend flow behaviour, env configuration, or asset pipeline behaviour changes, update `project-docs` in the same task.
- Default Git flow in this workspace is local `wip/<stream>` commits promoted directly with `git push origin HEAD:main`; do not publish remote `wip/<stream>` branches unless explicitly requested.

## Local Checks

- `npm run build`

## Sensitive Areas

- Do not casually change credential issuer metadata assumptions or authorization server relationships.
- Keep local certificates and generated trust artifacts out of version control.