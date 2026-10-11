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

For a possible security issue, email the maintainer privately at
[support.fastaqim@gmail.com](mailto:support.fastaqim@gmail.com) or
[asasesmail514@gmail.com](mailto:asasesmail514@gmail.com). Include the package
version, affected platform and a minimal reproduction without credentials or
user data. No response deadline is guaranteed. Other contact options are in
[SUPPORT.md](SUPPORT.md). Upstream issue links identify the original project
and are not this edition's private disclosure channel.

For Quran source/numbering issues, record the narration, edition, surah/ayah,
source manifest and exact observed discrepancy. Preserve original source
files while investigating rather than silently editing the canonical text.
