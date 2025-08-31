# Zero Click SSO Plugin

The Zero Click SSO plugin enables automatic login for Discourse forums when a single SSO provider is configured and local logins are disabled.

To work as intended, this plugin requires an IdP that supports silent login (OIDC or SAML). With providers like GitHub OAuth2, users may still see a consent screen.

* If the user is already logged in with the IdP, they are logged into Discourse without interaction
* If the user is not logged in with the IdP, they remain anonymous and can continue browsing
* If multiple SSO providers are configured, the plugin does nothing

If silent login fails, the plugin routes failures to its own `/auth/failure` handler. This controller swallows the error and redirects the user back to the forum, keeping them anonymous.
