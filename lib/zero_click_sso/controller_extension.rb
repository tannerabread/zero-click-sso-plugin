# frozen_string_literal: true

module ::ZeroClickSso
  module ControllerExtension
    def self.prepended(base)
      base.before_action :zero_click_login
      base.before_action :cleanup_zero_click_session
    end

    private

    def zero_click_login
      return unless should_attempt_zero_click?

      auth = Discourse.enabled_authenticators.first
      return unless auth
      return if auth.name.blank?

      session[:zero_click_attempted] = true
      session[:zero_click_origin] = request.original_fullpath

      redirect_to path("/auth/#{auth.name}?#{build_silent_query}")
    end

    def should_attempt_zero_click?
      SiteSetting.zero_click_sso_enabled &&
        !SiteSetting.enable_local_logins &&
        !SiteSetting.enable_local_logins_via_email &&
        request.format.html? &&
        !request.xhr? &&
        !request.path.end_with?(".webmanifest") &&
        current_user.blank? &&
        !request.path.start_with?("/auth/") &&
        !session[:zero_click_attempted] &&
        !session[:zero_click_failed] &&
        Discourse.enabled_authenticators.size == 1
    end

    def build_silent_query
      Rack::Utils.build_query(prompt: "none", origin: request.original_fullpath)
    end

    def cleanup_zero_click_session
      return unless session[:zero_click_failed]
      return if request.path.start_with?("/auth/")
        
      session.delete(:zero_click_attempted)
      session.delete(:zero_click_failed)
    end
  end
end
