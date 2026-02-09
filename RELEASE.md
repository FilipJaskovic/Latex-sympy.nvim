# Release Checklist (v0.2.0)

Use this checklist before publishing a release.

## 1) Verify clean release inputs

- [ ] `git status --short` only includes intended release files.
- [ ] No cache/log artifacts are tracked.
- [ ] `README.md`, `CHANGELOG.md`, and `doc/news.txt` are aligned with current code.

## 2) Run required quality gates

- [ ] `make test-python`
- [ ] `make test-smoke`
- [ ] `make test-ci`

## 3) Final docs and metadata checks

- [ ] `CHANGELOG.md` has a `0.2.0` section.
- [ ] `doc/news.txt` includes release notes and confirms no breaking changes.
- [ ] `README.md` command/config docs match implementation.

## 4) Create release commit and tag

- [ ] Commit release hardening changes.
- [ ] Create annotated tag:

```bash
git tag -a v0.2.0 -m "Release v0.2.0"
```

## 5) Push and publish

- [ ] Push branch.
- [ ] Push tag:

```bash
git push origin v0.2.0
```

- [ ] Publish GitHub release notes from `CHANGELOG.md`.
