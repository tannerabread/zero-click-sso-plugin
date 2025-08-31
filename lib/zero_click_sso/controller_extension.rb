# frozen_string_literal: true

module ::ZeroClickSso
  module ControllerExtension
    def self.prepended(base)
      base.before_action :zero_click_login
    end

    private

    def zero_click_login
      return unless SiteSetting.zero_click_sso_enabled
      return if SiteSetting.enable_local_logins

      # Only first page load HTML requests
      return unless request.format.html? && !request.xhr?

      # Detect if there is an active forum session
      return if current_user.present?

      # prevent loop with omniauth endpoints
      return if request.path.start_with?("/auth/")

      auths = Discourse.enabled_authenticators
      return unless auths.size == 1

      provider = auths.first.name
      return if provider.blank?

      qs = Rack::Utils.build_query(prompt: "none", origin: request.original_fullpath)
      redirect_to "/auth/#{provider}?#{qs}"
    end
  end
end
