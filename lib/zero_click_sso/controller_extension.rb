# frozen_string_literal: true

module ::ZeroClickSso
  module ControllerExtension
    def self.prepended(base)
      base.before_action :zero_click_login
      base.before_action :cleanup_zero_click_session
    end

    private

    def zero_click_login
      return unless SiteSetting.zero_click_sso_enabled
      return if SiteSetting.enable_local_logins || SiteSetting.enable_local_logins_via_email

      # Only first page load HTML requests
      return unless request.format.html? && !request.xhr?
      return if request.path.end_with?(".webmanifest")

      # Detect if there is an active forum session
      return if current_user.present?

      # prevent loop with omniauth endpoints
      return if request.path.start_with?("/auth/")

      return if session[:zero_click_attempted] || session[:zero_click_failed]

      auths = Discourse.enabled_authenticators
      return unless auths.size == 1

      provider = auths.first.name
      return if provider.blank?

      session[:zero_click_attempted] = true
      session[:zero_click_origin] = request.original_fullpath

      qs = Rack::Utils.build_query(prompt: "none", origin: request.original_fullpath)
      redirect_to path("/auth/#{provider}?#{qs}")
    end

    def cleanup_zero_click_session
      if session[:zero_click_failed] && !request.path.start_with?("/auth/")
        session.delete(:zero_click_attempted)
        session.delete(:zero_click_failed)
      end
    end
  end
end
