# disable_printer_discovery Linux scenario

This scenario checks present discovery services are stopped and disabled,
missing services remain absent, and repeat convergence is idempotent.
An unusable service inspection must fail instead of reporting compliance.

Use selector `disable_printer_discovery/linux` with the
[shared test procedure](../../README.md).
