# Wellumi legal pages (Privacy Policy & Terms)

Published with **GitHub Pages** from this folder (`docs/` on the `main` branch).

| Page | Live URL |
|---|---|
| Landing | <https://shaileshpatel008.github.io/VitaScan/> |
| Privacy Policy | <https://shaileshpatel008.github.io/VitaScan/privacy-policy.html> |
| Terms of Use | <https://shaileshpatel008.github.io/VitaScan/terms.html> |

The app opens these links from the consent screen and Profile
(`AppConstants.privacyPolicyUrl` / `AppConstants.termsUrl`). Use the Privacy Policy link in
Play Console → **App content → Privacy policy**.

`.nojekyll` makes GitHub serve the HTML files exactly as they are.

## Turning on GitHub Pages (once)

Repository **Settings → Pages** → Source: *Deploy from a branch* → Branch: `main`,
folder: `/docs` → **Save**. The site is live 1–2 minutes later.

## Editing

Edit the HTML files here, commit and push; the live pages update in about a minute.
Change the effective date when the content changes, and update the policy **before**
releasing features that handle data differently (Health Connect sync, cloud backup,
analytics, accounts).

**Contact:** the pages currently direct users to the developer email on Wellumi's Google
Play page. To show an email directly, replace that sentence in the contact sections of
`privacy-policy.html` and `terms.html`, and the footer line in `index.html`.

Have a lawyer review the text: it is written to match how the app works, but it is not
legal advice.
