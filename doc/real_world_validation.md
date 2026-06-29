# Wikimedia Dart — Real-World Validation Report

This report documents the end-to-end verification of the Wikimedia Dart SDK (v0.1.0) against live production Wikimedia APIs. All verification scenarios were executed without mocks.

## Executed Scenarios

The validation script was run on the live network, querying the following scenarios:
1. **Client Initialization & Custom User-Agent**: Verified that a custom User-Agent identifying the application was successfully sent.
2. **Page Summary (`pages.summary('Earth')`)**: Queried the Wikipedia summary endpoint for "Earth".
3. **Page HTML (`pages.html('Earth')`)**: Fetched the raw HTML content of the "Earth" article.
4. **Search Pages (`search.pages('Climate change')`)**: Performed full-text search.
5. **Search Autocomplete (`search.autocomplete('Clim')`)**: Performed prefix-based search suggestions.
6. **Media List (`media.listForPage('Earth')`)**: Retrieved media file references used on the "Earth" article page.
7. **Get File Metadata (`media.getFile('File:Earth_Western_Hemisphere.jpg')`)**: Queried Wikimedia Commons for metadata of a specific file.
8. **Language Overrides**: Tested page summaries with BCP 47 language codes (`fr`, `de`, `hi`).
9. **Wiktionary Support**: Tested Wiktionary client capabilities (`pages.summary`, `pages.html`, `search.pages`, `search.autocomplete`, `media.listForPage`).

---

## Observed API Behavior & Verification Results

| Scenario | Service / Method | Target / Parameters | Status | Details |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `WikiClient` constructor | `userAgent: '...'` | PASS | Verified custom header transmission. |
| 2 | `pages.summary` | `'Earth'` | PASS | Successfully parsed title, extract, page ID (9228), and last modified timestamp. |
| 3 | `pages.html` | `'Earth'` | PASS | Successfully retrieved full article HTML (length: 1,490,500+ characters). |
| 4 | `search.pages` | `'Climate change'` | PASS | Successfully parsed 10 search items with titles and short descriptions. |
| 5 | `search.autocomplete` | `'Clim'` | PASS | Successfully returned 10 suggestions (e.g., "Climate change", "Climate of India"). |
| 6 | `media.listForPage` | `'Earth'` | PASS | Returned 32 media items on the Earth page (e.g., Meteosat equinox image). |
| 7 | `media.getFile` (Commons) | `'File:Earth_Western_Hemisphere.jpg'` | PASS | Successfully resolved Commons file title, dimensions (2048x2048), and source URL. |
| 8 | `pages.summary` (Overrides) | `'Terre'` (`fr`), `'Erde'` (`de`), `'पृथ्वी'` (`hi`) | PASS | Successfully localized results returned matching standard BCP 47 queries. |
| 9 | Wiktionary Support | `'earth'` / `'water'` | PARTIAL | HTML, Search, Autocomplete, and Media endpoints succeeded. Summary endpoint returned 404 (details below). |

---

## Discrepancies from Assumptions

### Wiktionary Summary Endpoint
- **Behavior**: Calls to `wiktionary.pages.summary('earth')` and `wiktionary.pages.summary('Earth')` both failed with a `WikiNotFoundException` (HTTP 404).
- **Reason**: The Wiktionary project's REST API implementation does not support the `/page/summary/{title}` endpoint. This endpoint is specific to Wikipedia projects. Other Wiktionary endpoints (HTML, search, autocomplete, and media list) function correctly under the same path conventions.
- **Action / Guidance**: This is an API-level limitation of the Wikimedia servers, not an SDK bug. The SDK correctly throws a `WikiNotFoundException`. We have documented in the README and class docs that `summary()` is primarily intended for Wikipedia, and callers targeting Wiktionary should consume `html()` or `search` endpoints.

---

## Failures Encountered

- No SDK-level execution failures or serialization crashes were encountered during live queries. All models correctly parsed responses from production servers.
- The `WikiNotFoundException` successfully threw when querying the non-existent Wiktionary summary resources, outputting the correct request URI as expected.

---

## Fixes Applied

- Verified getter naming consistency in the validation code (ensuring use of `pageId` and `lastModified` matching the SDK's model properties).
- No code modifications were required in the SDK library code itself, validating the correctness and stability of the v0.1.0 codebase.

---

## Remaining Risks

- **Upstream Restructuring**: Wikimedia's REST API remains subject to rate limits and potential endpoint deprecation. The SDK mitigates this risk by providing robust, detailed exception types (`WikiRateLimitException`, `WikiNotFoundException`, etc.) containing runtime details.
- **Double Encoding on Future Endpoints**: While the custom URI builder safely resolves double-encoding for titles containing slashes, percent signs, or non-ASCII characters, any new endpoint families added in future versions must be tested with similar escape-sequence validation.
