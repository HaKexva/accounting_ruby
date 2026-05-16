# frozen_string_literal: true

module RubyUI
  class Carousel < Base
    def initialize(orientation: :horizontal, options: {}, initial_index: nil, **user_attrs)
      @orientation = orientation
      @options = options
      @initial_index = initial_index

      super(**user_attrs)
    end

    def view_template(&)
      div(**attrs, &)
    end

    private

    def default_attrs
      data = {
        controller: "ruby-ui--carousel",
        ruby_ui__carousel_options_value: default_options.merge(@options).to_json,
        action: %w[
          keydown.right->ruby-ui--carousel#keydownScrollNext
          keydown.left->ruby-ui--carousel#keydownScrollPrev
        ]
      }
      data[:ruby_ui__carousel_initial_index_value] = @initial_index unless @initial_index.nil?

      {
        class: [ "relative group", orientation_classes ],
        role: "region",
        aria_roledescription: "carousel",
        data: data
      }
    end

    def default_options
      {
        axis: (@orientation == :horizontal) ? "x" : "y"
      }
    end

    def orientation_classes
      (@orientation == :horizontal) ? "is-horizontal" : "is-vertical"
    end
  end
end
