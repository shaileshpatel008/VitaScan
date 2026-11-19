# Wellumi legal pages (Privacy Policy & Terms)

These pages are required by Google Play and the App Store. They are published
free with **GitHub Pages** from a small public repository, so the app's own
code stays private.

| File | Page |
|---|---|
| `index.html` | Landing page with links |
| `privacy-policy.html` | Privacy Policy |
| `terms.html` | Terms of Use |
| `icon.png` | Logo used by the pages |

## 1. Fill in the placeholders (required)

Replace these in **all three** HTML files (use Find & Replace in any editor):

| Placeholder | Replace with | Example |
|---|---|---|
| `{{DEVELOPER_NAME}}` | The developer or company name shown in Play Console | HMS Technologies |
| `{{CONTACT_EMAIL}}` | A support email users can write to | support@yourdomain.com |
| `{{EFFECTIVE_DATE}}` | The date you publish | 1 December 2026 |
| `{{GOVERNING_LAW}}` | Country / state whose law applies | India |

Have a lawyer review the text before launch: it is a starting draft written to
match how the app works, not legal advice.

## 2. Publish on GitHub Pages

1. Go to <https://github.com/new>.
2. **Repository name:** `wellumi-legal`. Select **Public**. Click **Create repository**.
3. On the new repo page, click **uploading an existing file**.
4. Drag in the four files from this folder: `index.html`, `privacy-policy.html`,
   `terms.html`, `icon.png`. Click **Commit changes**.
5. Open **Settings → Pages**.
   - **Source:** *Deploy from a branch*
   - **Branch:** `main`, folder `/ (root)` → **Save**
6. Wait 1–2 minutes, then open:
   - <https://shaileshpatel008.github.io/wellumi-legal/privacy-policy.html>
   - <https://shaileshpatel008.github.io/wellumi-legal/terms.html>

These are the exact links the app already opens (`AppConstants.privacyPolicyUrl`
and `AppConstants.termsUrl`). If you use a different repository name, update
those two constants to match.

## 3. Use the link in Play Console

- **App content → Privacy policy:** paste the privacy-policy link.
- **Store listing:** the same link is shown on your listing automatically.

## Updating later

Edit the file on GitHub (pencil icon) and commit; the site updates in about a
minute. Change `{{EFFECTIVE_DATE}}` whenever the content changes, and update the
policy **before** releasing features that handle data differently (for example
turning on Health Connect sync or cloud backup).
