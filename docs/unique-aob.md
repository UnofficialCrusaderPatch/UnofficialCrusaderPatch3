# Unique executable AOB bindings

`core.AOBScanUnique(pattern, name)` returns one verified instruction address or
raises a named missing/ambiguous diagnostic. `utils.AOBExtractUnique(pattern,
name, unpacked)` uses the same capture syntax and result shape as `AOBExtract`,
but verifies uniqueness before reading any operands or relative targets.

Run these during module preparation before enable-time patches. A cached match
is never proof of uniqueness. The existing `data.cache.AOB` owns the result:
only a successful bounded check updates its normal cache entry. A stale entry
or one pointing to non-code bytes is replaced by the verified code match; an
ambiguity leaves it untouched. No second full-process validation scan is needed.

RPS `scanForAOBInMainModule` enumerates the first two matches in executable main
image pages using its existing parser/scanner and Windows memory metadata. It
includes overlapping matches and protection boundaries. No private PE scanner,
image hash whitelist, fixed game address or per-frame resolution is introduced.
UI and other subsystem exports should still be consumed instead of rescanned.

Prerequisite: RPS 1.5.3 with https://github.com/gynt/RuntimePatchingSystem/pull/16 .
The dependency update must ship with the Lua facade; stock 3.0.7 does not provide
this capability. Existing `AOBScan`/`AOBExtract` callers keep their API/behavior,
apart from the corrected underlying native scan bounds.

Validation: `python -m unittest discover -s tests -p test_unique_aob.py -v`
(with `lupa==2.5`) exercises the actual cache/facade/decoder. Native range,
guard, overlapping-match and code-page tests belong to the RPS prerequisite.
Consumer acceptance and full framework packaging remain separate checks.
