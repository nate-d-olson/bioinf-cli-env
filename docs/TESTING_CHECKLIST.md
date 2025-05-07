# Testing Checklist for Comprehensive Platform Compatibility

## macOS Testing
- [ ] Verify installer (`install.sh`) works with/without `brew`.
- [ ] Verify no accidental invocation of `sudo`.
- [ ] Confirm Azure CLI explicit check and installation instructions.
- [ ] Test Micromamba user-space setup.
- [ ] Validate bash standardization across scripts.

## Ubuntu Testing
- [ ] Execute `install.sh` without `sudo`, ensuring fallback methods activate correctly.
- [ ] Confirm Azure CLI explicit handling when not pre-installed.
- [ ] Verify Micromamba installs without privileges.
- [ ] Ensure scripts run explicitly with `bash`.

## SLURM Cluster Environment
- [ ] Perform user-space installations of Micromamba and CLI tools.
- [ ] Confirm Azure CLI explicit checks behave correctly in restricted environments.
- [ ] Check that all utilities and environment scripts perform correctly under bash.

## Cross-platform Regression Tests
- [ ] Validate all logs and error messages clearly inform the user of issues and next steps.
- [ ] Comprehensive end-to-end pipeline and functionality testing.

## Documentation and Cleanup
- [ ] Update user-facing documentation based on test outcomes and feedback.
- [ ] Clean up unnecessary files and streamline scripts based on testing conclusions.

## Final Review
- Conducted by:
- Date:
- Outcome and action items documented clearly for next stages.