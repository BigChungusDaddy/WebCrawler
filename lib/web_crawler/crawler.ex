defmodule Crawler do
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://dailyutahchronicle.com/"

  @impl Crawly.Spider
  def init(), do: [start_urls: [
    "https://dailyutahchronicle.com/category/news/",
    "https://dailyutahchronicle.com/category/investigative/",
    "https://dailyutahchronicle.com/category/opinion/",
    "https://dailyutahchronicle.com/category/ae/",
    "https://dailyutahchronicle.com/category/sports/"
    ]
  ]

  @impl Crawly.Spider
  def parse_item(response) do
    # Parse response body to document
    {:ok, document} = Floki.parse_document(response.body)
    # Create item (for pages where items exists)
    items =
      document
      |> extract_comments()

    next_requests =
      document
      |> extract_all_urls()
      |> Crawly.Utils.requests_from_urls()

      %{items: items, requests: next_requests}
  end

  defp extract_all_urls(document) do
    page_num_urls = extract_url_from_page_number(document)
    page_main_urls = extract_url_from_category_page(document)
    page_latest_stories_urls = extract_url_from_latest_stories(document)
    page_staff_urls = extract_url_from_staff_page(document)

    temp_list_1 = page_num_urls ++ page_main_urls
    temp_list_2 = page_latest_stories_urls ++ page_staff_urls

    urls = temp_list_1 ++ temp_list_2 |> Enum.uniq()
    urls
  end

  defp extract_url_from_page_number(document) do
    elements = document |> Floki.find(".navigation")
    extract_urls(elements)
  end

  defp extract_url_from_category_page(document) do
    elements = document |> Floki.find(".catlist-textarea-with-media")
    extract_urls(elements)
  end

  defp extract_url_from_latest_stories(document) do
    elements = document |> Floki.find(".sno-story-card-link")
    extract_urls(elements)
  end

  defp extract_url_from_staff_page(document) do
    elements = document |> Floki.find(".catlist-tile-textarea-with-media")
    extract_urls(elements)
  end

  defp extract_comments(document) do
    comment_details = document |> Floki.find(".comment-details")
    comment_metas = Enum.map(comment_details, fn each_comment -> Floki.find(each_comment, ".sno-comment-meta") end)
    comment_text = Enum.map(comment_details, fn each_comment -> Floki.find(each_comment, ".sno-comment-text") end)
    name_elements = Enum.map(comment_metas, fn each_meta -> Floki.find(each_meta, ".sno-comment-name") end)
    time_elements = Enum.map(comment_metas, fn each_meta -> Floki.find(each_meta, ".sno-comment-date") end)

    names = Enum.map(name_elements, fn each_element -> Floki.text(each_element) end)
    times = Enum.map(time_elements, fn each_element -> Floki.text(each_element) end)
    comments = Enum.map(comment_text, fn each_comment -> Floki.text(each_comment, sep: "\n") end)

    filtered_comments = Enum.zip([names | [times | [comments | []]]]) |> Enum.filter(& !is_nil(&1))
    filtered_comments |> Enum.map(fn each_comment ->
      %{
        name: elem(each_comment, 0),
        time: elem(each_comment, 1),
        comment: elem(each_comment, 2)
      }
    end)
  end

  defp extract_urls(elements) do
    listOfElements = Enum.map(elements,  fn element -> Floki.find(element, "a") end)
    urls = Enum.map(listOfElements, fn element -> Floki.attribute(element, "href") end)
    urls = List.flatten(urls)
    urls
  end

  defp filter_comments(list_of_comments, desired_name) do
    list_of_comments
    |> Enum.map(fn each_comment ->
      if elem(each_comment, 0) == desired_name do
        each_comment
        end
      end)
  end

end
