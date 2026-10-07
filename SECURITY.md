# Security and content integrity

The package contains public Quran assets and public catalog/clip URLs. It
does not require Supabase credentials or bundle an authentication service.

- Never commit API secrets, tokens, signing keys or local environment files.
- Validate user-provided page, surah, verse and clip references before use.
- Do not send Quran bookmarks or other host-app user data to a URL provider.
- Keep network source identities pinned where manifests specify them.
- Review custom API base URLs, HTTP clients and picture builders in the host
  application; they are caller-controlled extension points.
- Do not display raw network exceptions as user-facing error messages.

For a possible security issue, contact the maintainer privately through an
already established channel and include a minimal reproduction without
credentials or user data. No dedicated private reporting endpoint has been
configured for this local repository. Upstream issue links identify the
original project and are not a private disclosure channel.

For Quran source/numbering issues, record the narration, edition, surah/ayah,
source manifest and exact observed discrepancy. Preserve original source
files while investigating rather than silently editing the canonical text.
