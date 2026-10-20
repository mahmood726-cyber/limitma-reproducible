# 1.1.0 (local, unreleased) [ARCHIVE DOI: limitma-reproducible v1.1.0 — pending release]

Adds `v1_1/`: the leave-one-out limit tier (allmeta 9b232cc; 31,514/31,514 node replay checks; R reference regenerated in full, 5,304/5,304 rows byte-identical) and the bias-sensitivity tier of allmeta v1.7.0 (16,097 checks: 15,928/15,928 replayed in node, 169 rendering checks from the archived browser run; R reference regenerated in full, every R value bit-identical). `validate.R` runs the layer after v1; `ARCHIVE_V1_1_ONLY=1` skips the v1 refit. v1 files and counts unchanged; verify_archive.py now expects metadata version 1.1.0; SOURCE_SHA256.json regenerated.

# 1.0.0

Archive of DL + beta0 validation, allmeta 4a053dd (PR #115), plus validation panel e431057 (PR #117); both in allmeta v1.4.0. Before: 44772/55525; after: 55524/55525. One R refusal remains. Corrected curve geometry, axis range, disabled unsupported log controls, and stale/singular-result handling; numerical estimators unchanged.
