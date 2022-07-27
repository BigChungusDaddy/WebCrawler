# WebCrawler

A simple web crawler used to extract comments on https://dailyutahchronicle.com/.

## To Use

1. Install Elixir according to https://elixir-lang.org/install.html.

2. Fetch dependencies:

```console
mix deps.get
```

3. Start the crawl:
``` console
iex -S mix
iex(1)> Crawly.Engine.start_spider(Crawler)
```
