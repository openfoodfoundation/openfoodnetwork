# frozen_string_literal: true

class ExampleComponentStories < ViewComponent::Storybook::Stories
  story(:with_short_text) do
    controls do
      text(:title, 'OK')
    end
  end

  story(:with_long_text) do
    controls do
      text(:title, 'This is a long text')
    end
  end
end
