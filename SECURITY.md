# Security Policy

SekerCallMe handles credentials and publishes services on a local network. Please treat security reports carefully.

## Supported versions

Security fixes are applied to the latest commit on `main`. The project does not currently maintain separate release branches.

## Reporting a vulnerability

Please use GitHub's **Security** tab and choose **Report a vulnerability** to send a private report. Do not open a public issue for suspected vulnerabilities or include live tokens, passwords, LAN addresses, or topic names in public content.

Include:

- the affected component and configuration;
- the expected and observed behavior;
- reproduction steps or a minimal proof of concept;
- the likely impact; and
- any suggested mitigation, if available.

You should receive an initial response within seven days. Please allow time for a fix before public disclosure.

## Deployment boundary

The default HTTP deployment is intended only for a trusted LAN. It must not be exposed directly to the public internet. Use a trusted VPN or an authenticated HTTPS reverse proxy across untrusted networks.

If a real credential may have been disclosed, rotate it immediately. Do not wait for the vulnerability report to be processed.
