angular.module("admin.indexUtils").factory "PagedFetcher", (dataFetcher) ->
  new class PagedFetcher
    # Given a URL like http://example.com/foo?page=::page::&per_page=20
    # And the response includes an attribute pages with the number of pages to fetch
    # Fetch each page async, and call the pageCallback callback with the resulting data
    # Developer note: this class should not be re-used!
    page: 1
    last_page: 1

    fetch: (url, pageCallback) ->
      @fetchPages(url, @page, pageCallback)

    urlForPage: (url, page) ->
      url.replace("::page::", page)

    fetchPages: (url, page, pageCallback) ->
      dataFetcher(@urlForPage(url, page)).then (data) =>
        @page++
        @last_page = data.pagination.pages

        pageCallback(data) if pageCallback

        if @page <= @last_page
          @fetchPages(url, @page, pageCallback)

