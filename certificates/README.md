# Checking receipts and optional signatures

This directory can hold a selected local checking run: its receipt, exactly the
logs whose hashes it lists, and an optional signature. The author reports a
local check of the released file. A receipt records observed command outcomes;
it does not certify the mathematical interpretation of the Lean statement.
See [CERTIFICATE.md](../exact-fit-local/CERTIFICATE.md).

## Publishing a run

1. Create a directory named with the date and the identity you intend to make
   public.
2. Copy the chosen receipt and exactly the logs it names. Do not copy every log
   in the working directory: it may contain other runs or local information.
3. Inspect every file before publication, including absolute paths, account
   names, host names and signatures. The current scanner prints only a basename,
   but other tools or errors may still reveal local paths.
4. From the selected directory, verify the hashes:

```bash
sha256sum -c <(sed -n '/^SHA-256 of the logs:/,/^This receipt/p' receipt-*.txt | sed '1d;$d')
```

Do not edit a log and retain the old receipt as an attestation of the edited
bytes. If redaction is needed, keep the evidence relationship explicit or make
a new clean run.

## Optional signature

Signing identifies who attests to a receipt's bytes. It does not independently
verify the commands or mathematical statement. For example:

```bash
ssh-keygen -Y sign -f ~/.ssh/id_ed25519 -n file receipt-<UTC>.txt
```

Publish only the signature, receipt and intended public key, never the private
key. Verification requires a trusted `allowed_signers` file:

```bash
ssh-keygen -Y verify -f allowed_signers -I <public-identity> -n file \
  -s receipt-<UTC>.txt.sig < receipt-<UTC>.txt
```
