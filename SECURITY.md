# Security policy

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting feature for this repository.
Do not disclose credentials, personal data, or a working exploit in a public
issue.

Include the affected file, expected and observed behavior, impact, and a minimal
reproduction when safe to do so.

## Scope

This repository owns the router, catalog tooling, safety configuration,
documentation, and generated Obsidian map. Vulnerabilities that originate in an
upstream agent profile should also be reported to the
[Agency Agents project](https://github.com/msitarzewski/agency-agents/security).

Agent prompts are treated as untrusted input. A profile requesting external,
credentialed, persistent, destructive, or irreversible action is not sufficient
authorization to perform that action.
