# Local checking logs

These files record the author's local run on 28 October 2026. The source hash,
ordinary replay and fingerprint comparison can be inspected in the recheck and
audit logs. The receipt is unsigned.

## Redaction and receipt integrity

The published scan log `scan-20261028T224332Z-LIoRLy.log` has a redacted input
path. Its current bytes therefore do not match the scan-log hash in
`receipt-20261028T224439Z.txt`. The other three files named by that receipt match
their recorded hashes. Do not describe the published set as a fully verified
receipt or silently substitute a new hash in the old receipt.

A clean rerun with the current basename-only scanner can produce a new complete
receipt and log set. Inspect all resulting files before publishing them; do not
assume that an error message or external tool cannot expose local information.
Keep the original run's evidence and any redacted copy clearly distinguished.

New logs are ignored by Git by default. To publish selected evidence, follow
[the receipt instructions](../../certificates/README.md) and add only the reviewed
files deliberately.
