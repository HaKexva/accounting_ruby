# frozen_string_literal: true

module RubyUI
  class Layout < Base
    include Phlex::Rails::Helpers::Routes

    APP_NAME = "Accounting Ruby"

    def view_template(&block)
      div(class: "flex h-screen w-full overflow-hidden bg-background") do
        render_desktop_sidebar

        div(class: "flex flex-col flex-1 w-full min-w-0") do
          render_mobile_header

          main(class: "flex-1 overflow-y-auto overflow-x-hidden p-4") do
            div(class: "w-full max-w-6xl mx-auto px-4 sm:px-6 space-y-4") do
              render_flash_messages
              block.call
            end
          end
        end
      end
    end

    private

    def render_flash_messages
      return if flash.blank?

      div(class: "mb-4 space-y-2") do
        if flash[:alert].present?
          div(
            class: "py-2 px-3 bg-red-50 text-red-600 font-medium rounded-md border border-red-200",
            role: "alert"
          ) { flash[:alert] }
        end
        if flash[:notice].present?
          div(
            class: "py-2 px-3 bg-green-50 text-green-600 font-medium rounded-md border border-green-200",
            role: "status"
          ) { flash[:notice] }
        end
      end
    end

    def flash
      view_context.flash
    end

    def render_desktop_sidebar
      div(class: "hidden lg:flex w-48 shrink-0 flex-col border-r bg-card h-full") do
        div(class: "p-6") do
          h1(class: "text-lg font-semibold") { APP_NAME }
        end
        div(class: "flex-1 px-4 space-y-2") do
          render_nav_links
        end
      end
    end

    def render_mobile_header
      header(class: "lg:hidden flex items-center justify-between border-b px-4 py-3 bg-card shrink-0") do
        span(class: "font-semibold") { APP_NAME }

        Sheet do
          SheetTrigger do
            Button(variant: :ghost, size: :icon) do
              menu_icon
            end
          end

          SheetContent(side: :right, class: "w-[14rem] max-w-[85vw] flex flex-col") do
            SheetHeader do
              SheetTitle { "Menu" }
            end
            div(class: "mt-4 flex-1 flex flex-col gap-2") do
              render_nav_links
            end
          end
        end
      end
    end

    def render_nav_links
      nav_link(href: root_path) { "Actual expenditure" }
      nav_link(href: revenue_budgets_path) { "Revenue budgets" }
      nav_link(href: expenditure_budgets_path) { "Expenditure budgets" }
      nav_link(href: settings_path) { "Settings" }
    end

    def nav_link(href:, &block)
      active = view_context.current_page?(href)
      link_class = "block px-4 py-2 rounded-md text-sm font-medium transition-colors "
      link_class += active ? "bg-accent text-accent-foreground" : "hover:bg-accent hover:text-accent-foreground"
      a(href: href, class: link_class, &block)
    end

    def menu_icon
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        width: "24",
        height: "24",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: "2",
        stroke_linecap: "round",
        stroke_linejoin: "round",
        class: "lucide lucide-menu"
      ) do |s|
        s.path(d: "M4 12h16")
        s.path(d: "M4 6h16")
        s.path(d: "M4 18h16")
      end
    end
  end
end
