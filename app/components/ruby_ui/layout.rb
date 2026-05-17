# frozen_string_literal: true

module RubyUI
  class Layout < Base
    include Phlex::Rails::Helpers::Routes

    APP_NAME = "記帳"

    NAV_ITEMS = [
      { href: :root, label: "實際支出", icon: :expense },
      { href: :budgets, label: "預算", icon: :budget },
      { href: :settings, label: "設定", icon: :settings }
    ].freeze

    def view_template(&block)
      div(class: "flex h-screen w-full overflow-hidden bg-background text-foreground antialiased") do
        render_desktop_sidebar

        div(class: "flex flex-col flex-1 w-full min-w-0 min-h-0") do
          render_mobile_header

          main(
            id: "app-main-scroll",
            class: [
              "app-main-gradient flex-1 overflow-y-auto overflow-x-hidden min-h-0",
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
              "rounded-xl border px-4 py-3 text-sm font-medium leading-snug shadow-sm",
              "border-red-500/30 bg-red-500/[0.08] text-red-900",
              "dark:border-red-500/35 dark:bg-red-950/45 dark:text-red-100"
            ].join(" "),
            role: "alert"
          ) { flash[:alert] }
        end
        if flash[:notice].present?
          div(
            class: [
              "rounded-xl border px-4 py-3 text-sm font-medium leading-snug shadow-sm",
              "border-emerald-500/30 bg-emerald-500/[0.08] text-emerald-950",
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
      div(
        class: [
          "hidden lg:flex w-56 shrink-0 flex-col border-r border-border/80",
          "bg-sidebar/95 backdrop-blur-md h-full shadow-sm shadow-black/[0.03]"
        ].join(" ")
      ) do
        div(class: "border-b border-sidebar-border/80 px-5 py-6") do
          div(class: "flex items-center gap-3") do
            div(
              class: [
                "flex size-9 shrink-0 items-center justify-center rounded-lg",
                "bg-primary text-primary-foreground shadow-sm"
              ].join(" ")
            ) do
              nav_icon(:expense, css_class: "size-5")
            end
            div(class: "min-w-0") do
              h1(class: "text-lg font-semibold tracking-tight text-sidebar-foreground") { APP_NAME }
              p(class: "text-xs text-muted-foreground") { "個人帳務" }
            end
          end
        end
        nav(class: "flex-1 px-3 py-4 flex flex-col gap-1", aria: { label: "主要導覽" }) do
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
          "shadow-sm shadow-black/[0.03]",
          "pt-[max(0.75rem,env(safe-area-inset-top,0px))]"
        ].join(" ")
      ) do
        div(class: "flex items-center gap-2") do
          div(class: "flex size-8 items-center justify-center rounded-md bg-primary text-primary-foreground") do
            nav_icon(:expense, css_class: "size-4")
          end
          span(class: "font-semibold tracking-tight") { APP_NAME }
        end

        Sheet do
          SheetTrigger do
            Button(variant: :ghost, size: :icon) do
              menu_icon
            end
          end

          SheetContent(side: :right, class: "w-[15rem] max-w-[85vw] flex flex-col") do
            SheetHeader do
              SheetTitle { "選單" }
            end
            nav(class: "mt-4 flex-1 flex flex-col gap-2", aria: { label: "主要導覽" }) do
              render_nav_links
            end
          end
        end
      end
    end

    def render_nav_links
      NAV_ITEMS.each do |item|
        href = resolve_nav_href(item[:href])
        nav_link(href: href, icon: item[:icon], label: item[:label])
      end
    end

    def resolve_nav_href(key)
      case key
      when :root then root_path
      when :budgets then budgets_path
      when :settings then settings_path
      else root_path
      end
    end

    def nav_link(href:, icon:, label:)
      active = view_context.current_page?(href)
      link_class = [
        "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all border",
        active ?
          "border-primary/25 bg-primary/10 text-primary shadow-sm" :
          "border-transparent text-foreground/85 hover:border-border/60 hover:bg-accent/80 hover:text-accent-foreground"
      ].join(" ")
      a(href: href, class: link_class) do
        span(
          class: [
            "flex size-8 shrink-0 items-center justify-center rounded-md",
            active ? "bg-primary/15 text-primary" : "bg-muted/60 text-muted-foreground"
          ].join(" ")
        ) { nav_icon(icon, css_class: "size-4") }
        span(class: "truncate") { label }
      end
    end

    def nav_icon(name, css_class: "size-4")
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
        class: css_class
      ) do |s|
        case name
        when :expense
          s.path(d: "M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6")
        when :budget
          s.path(d: "M21 12V7H5a2 2 0 0 1 0-4h14v4")
          s.path(d: "M3 7v10a2 2 0 0 0 2 2h16v-5")
          s.path(d: "M7 12h4")
        when :settings
          s.path(d: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z")
          s.circle(cx: "12", cy: "12", r: "3")
        end
      end
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
