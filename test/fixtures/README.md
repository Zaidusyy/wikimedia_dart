# Wikimedia Dart Fixtures

This directory contains verbatim API responses captured from the live
Wikimedia REST API. They are the ground truth for model parsing tests.

## Capturing fixtures

```bash
curl "https://en.wikipedia.org/api/rest_v1/page/summary/Earth" \
  > test/fixtures/responses/page_summary_earth.json

# Note: The /page/related endpoint has been decommissioned by Wikimedia.
# page_related_earth_legacy.html preserves the original decommissioned page error response.
# page_related_earth_contract.json is a simulated contract-compliant mock response for testing.

curl "https://en.wikipedia.org/w/rest.php/v1/search/page?q=climate+change&limit=3" \
  > test/fixtures/responses/search_climate_change.json

curl "https://en.wikipedia.org/api/rest_v1/page/media-list/Earth" \
  > test/fixtures/responses/media_list_earth.json
```

**Important:** Do not hand-craft fixture JSON. Capture verbatim from the
live API to ensure tests reflect real response shapes. For decommissioned endpoints
or special test conditions, simulated contract fixtures are placed in `*_contract.json`.

