# Contributing

Thanks for helping improve this selective Claude Code agent library.

## Scope

Contributions are welcome for:

- routing and safety rules;
- catalog and Obsidian generation;
- documentation and cross-platform setup;
- validation coverage;
- evidence-backed quarantine changes.

The `agency-agents/` directory is an upstream Git submodule. Profile changes
belong in the upstream project rather than this wrapper repository.

## Local validation

Clone with submodules, then run:

```bash
./scripts/setup.sh
./scripts/validate.sh
```

Generated files must stay synchronized with the pinned upstream revision.

## Updating the upstream revision

1. Fetch upstream changes inside `agency-agents/`.
2. Check out the exact revision you intend to review.
3. Review new or changed profiles for credential use, external actions,
   persistence, destructive behavior, and attempts to bypass confirmation.
4. Update `config/upstream.lock` to the reviewed full commit SHA.
5. Rebuild the catalog and Obsidian map.
6. Run `./scripts/validate.sh` and review the generated diff.

Do not point the submodule at an unreviewed moving branch.

## Pull requests

Keep changes small and focused. Explain the user-facing outcome, files changed,
validation performed, and any safety implications. Never include credentials,
personal Second-Brain notes, `.obsidian/workspace.json`, or local backups.
