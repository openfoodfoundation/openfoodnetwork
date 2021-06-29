class FilterFieldComponentStories < ViewComponent::Storybook::Stories
  story(:default) do
    controls do
      text(:title, "Categories")
      boolean(:open, false)
      array(:options, [])
      text(:selected, "")
    end
  end

  story(:open) do
    controls do
      text(:title, "Categories")
      boolean(:open, true)
      array(:options, ["label 1", "label 2", "label 3", "label 4", "label 5", "label 6", "label 7"])
      text(:selected, "")
    end
  end

  story(:one_selected_option_and_closed) do
    controls do
      text(:title, "Categories")
      boolean(:open, false)
      array(:options, ["label 1", "label 2", "label 3", "label 4", "label 5", "label 6", "label 7"])
      text(:selected, "label 3")
    end
  end

  story(:one_selected_option_and_open) do
    controls do
      text(:title, "Categories")
      boolean(:open, true)
      array(:options, ["label 1", "label 2", "label 3", "label 4", "label 5", "label 6", "label 7"])
      text(:selected, "label 3")
    end
  end
end
