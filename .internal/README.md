# internal/

Specs for changing the SDLC rules themselves — not SDLC artifacts, not
lifecycle reading material.

* No lifecycle step reads or writes here during a run — not dispatched
  workers, not the reviewer, not the orchestrating session acting in its
  lifecycle role. No lifecycle step ever updates the lifecycle rules.
* The rules (skills, agents, templates, `cli`, `docs/`) are maintained
  separately, informed by these specs — a maintenance track outside the
  intent → dispatch → ship → review → sync loop.
* Treat any diff from a lifecycle run touching `internal/` as scope leakage.
* Specs live in `internal/plans/<YYYY-MM-DD>-<topic>.md`.
