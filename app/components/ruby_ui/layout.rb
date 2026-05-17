# frozen_string_literal: true

module RubyUI
  class Layout < Base
    include Phlex::Rails::Helpers::Routes

    APP_NAME = "記帳"

    def view_template(&block)
      div(class: "flex h-screen w-full overflow-hidden bg-background text-foreground antialiased") do
        render_desktop_sidebar

        div(class: "flex flex-col flex-1 w-full min-w-0 min-h-0") do
          render_mobile_header

          main(
            id: "app-main-scroll",
            class: [
              "flex-1 overflow-y-auto overflow-x-hidden min-h-0",
              "px-4 py-6 sm:px-6 sm:py-8 lg:px-10",
              "pt-[max(1rem,env(safe-area-inset-top,0px))]",
              "pb-[max(1rem,env(safe-area-inset-bottom,0px))]"
            ].join(" ")
          ) do
            div(class: "w-full max-w-6xl mx-auto space-y-6 lg:space-y-8") do
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

      div(class: "space-y-3") do
        if flash[:alert].present?
          div(
            class: [
              "rounded-lg border px-4 py-3 text-sm font-medium leading-snug",
              "border-red-500/30 bg-red-500/[0.08] text-red-900",
              "dark:border-red-500/35 dark:bg-red-950/45 dark:text-red-100"
            ].join(" "),
            role: "alert"
          ) { flash[:alert] }
        end
        if flash[:notice].present?
          div(
            class: [
              "rounded-lg border px-4 py-3 text-sm font-medium leading-snug",
              "border-emerald-500/25 bg-emerald-500/[0.08] text-emerald-950",
              "dark:border-emerald-500/35 dark:bg-emerald-950/40 dark:text-emerald-100"
            ].join(" "),
            role: "status"
          ) { flash[:notice] }
        end
      end
    end

    def flash
      view_context.flash
    end

    def render_desktop_sidebar
      div(class: "hidden lg:flex w-52 shrink-0 flex-col border-r border-border/80 bg-card/95 backdrop-blur-sm h-full") do
        div(class: "border-b border-border/60 px-5 py-5") do
          div(class: "flex items-center gap-2") do
            span(class: "size-2 shrink-0 rounded-full bg-primary ring-4 ring-primary/15", aria: { hidden: true })
            h1(class: "text-lg font-semibold tracking-tight") { APP_NAME }
          end
          p(class: "mt-2 text-xs leading-relaxed text-muted-foreground") { "個人帳務" }
        end
        div(class: "flex-1 px-3 py-4 flex flex-col gap-1") do
          render_nav_links
        end
      end
    end

    def render_mobile_header
      header(
        id: "app-mobile-header",
        class: [
          "lg:hidden flex items-center justify-between shrink-0",
          "border-b border-border/80 bg-card/95 backdrop-blur-md px-4 py-3",
          "pt-[max(0.75rem,env(safe-area-inset-top,0px))]"
        ].join(" ")
      ) do
        span(class: "font-semibold tracking-tight") { APP_NAME }

        Sheet do
          SheetTrigger do
            Button(variant: :ghost, size: :icon) do
              menu_icon
            end
          end

          SheetContent(side: :right, class: "w-[14rem] max-w-[85vw] flex flex-col") do
            SheetHeader do
              SheetTitle { "選單" }
            end
            div(class: "mt-4 flex-1 flex flex-col gap-2") do
              render_nav_links
            end
          end
        end
      end
    end

    def render_nav_links
      nav_link(href: root_path) { "實際支出" }
      nav_link(href: budgets_path) { "預算" }
      nav_link(href: settings_path) { "設定" }
    end

    def nav_link(href:, &block)
      active = view_context.current_page?(href)
      base = "block rounded-lg px-4 py-2.5 text-sm font-medium transition-colors border "
      link_class = base + (
        active ? "bg-accent text-accent-foreground border-accent/30 shadow-sm" :
          "border-transparent text-foreground/90 hover:bg-accent/80 hover:text-accent-foreground hover:border-border/50"
      )
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
