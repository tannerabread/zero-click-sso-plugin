# Zero Click SSO Plugin

This plugin allows automatic login for users without requiring them to enter their credentials manually.

It works for configurations with `enable local logins` disabled and a single SSO configured.

To work as intended, this plugin requires an IdP that supports silent login (OIDC or SAML). With providers like GitHub OAuth2, users may still see a consent screen.
