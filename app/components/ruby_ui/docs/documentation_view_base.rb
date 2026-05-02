# frozen_string_literal: true

module RubyUI
  class DocumentationViewBase < Phlex::HTML
    def Heading(level:, &)
      tag = :"h#{level}"
      send(tag, &)
    end

    def component_files(component_name)
      []
    end

    def Text(&)
      p(&)
    end

    def InlineLink(href:, target: nil, class: nil, &)
      a(href: href, target: target, class: binding.local_variable_get(:class), &)
    end

    def Alert(&)
      div(&)
    end

    def AlertTitle(&)
      h4(&)
    end

    def AlertDescription(&)
      p(&)
    end

    def docs_sheet_path
      "#"
    end

    def docs_separator_path
      "#"
    end

    def docs_accordion_path
      "#"
    end

    def docs_alert_path
      "#"
    end

    def docs_alert_dialog_path
      "#"
    end

    def docs_aspect_ratio_path
      "#"
    end

    def docs_avatar_path
      "#"
    end

    def docs_badge_path
      "#"
    end

    def docs_installation_path
      "#"
    end

    def InlineCode(&)
      code(&)
    end
  end
end
