---
change: change-20260815-wsl-1password-authority
role: verification
---

<!-- lifecycle is owned by change.md -->

# Verification

```sh
python3 modules/credproxy/tests/probe_credential_authority.py --self-test
python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
bash -n modules/credproxy/install.sh modules/credproxy/setup.sh
```

Real-host verification runs install/setup without printing or recording the token,
then checks the user unit and Context Fabric route health.
