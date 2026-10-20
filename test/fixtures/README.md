# Fixtures

Responses captured from the live Wikimedia API with curl and saved as is.
The model and client tests parse these, so they show the real shapes.

## Capturing

```bash
UA='wikimedia_dart-tests (https://github.com/Zaidusyy/wikimedia_dart)'

curl -A "$UA" "https://en.wikipedia.org/api/rest_v1/page/summary/Earth" \
  > test/fixtures/responses/page_summary_earth.json

curl -A "$UA" "https://en.wikipedia.org/w/rest.php/v1/search/page?q=climate+change&limit=3" \
  > test/fixtures/responses/search_climate_change.json

curl -A "$UA" "https://en.wikipedia.org/api/rest_v1/page/media-list/Earth" \
  > test/fixtures/responses/media_list_earth.json

curl -A "$UA" "https://en.wikipedia.org/w/rest.php/v1/search/page?q=morelike:Earth&limit=5" \
  > test/fixtures/responses/page_related_earth_morelike.json
```

Wikimedia rejects requests without a User-Agent, hence the `-A`. Don't edit
the captured JSON by hand; capture it again instead.
