# Release Checklist

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

- [ ] `CHANGELOG.md` has a section for the target release version.
- [ ] `doc/news.txt` includes release notes and confirms no breaking changes.
- [ ] `README.md`, `doc.md`, and `FEATURES.md` are aligned with implementation.

## 4) Create release commit and tag

- [ ] Commit release changes.
- [ ] Create annotated tag:

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
```

## 5) Push and publish

- [ ] Push branch.
- [ ] Push tag:

```bash
git push origin vX.Y.Z
```

- [ ] Publish GitHub release notes from `CHANGELOG.md`.
