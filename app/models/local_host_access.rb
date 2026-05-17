# frozen_string_literal: true

# Detects browser requests to localhost so development can skip the login screen.
module LocalHostAccess
  LOCAL_LOGIN_SKIP_HOSTS = %w[localhost 127.0.0.1 ::1].freeze

  module_function

  def localhost_host?(host)
    normalized = host.to_s.downcase.delete_prefix("[").delete_suffix("]")
    LOCAL_LOGIN_SKIP_HOSTS.include?(normalized)
  end
end
