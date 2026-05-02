# frozen_string_literal: true

module RubyUI
  class ComponentSetupTabs < Phlex::HTML
    def initialize(component_name:)
      @component_name = component_name
    end

    def view_template
      # Minimal stub - empty by default
    end
  end
end
