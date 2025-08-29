# frozen_string_literal: true

# name: zero-click-sso
# about: Zero Click SSO Login
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: https://github.com/tannerabread/zero-click-sso-plugin
# required_version: 2.7.0

enabled_site_setting :zero_click_sso_enabled

module ::ZeroClickSso
  PLUGIN_NAME = "zero-click-sso"
end

require_relative "lib/zero_click_sso/engine"

after_initialize do
  # Code which should run after Rails has finished booting
  Rails.logger.info("Zero Click SSO plugin initialized")

  module ::ZeroClickSso
    module ControllerExtension
      def self.prepended(base)
        base.before_action :zero_click_login
      end

      private

      def zero_click_login
        return unless SiteSetting.zero_click_sso_enabled
        return if SiteSetting.enable_local_logins
        return unless request.format.html? && !request.xhr?
        # Detect if there is an active forum session
        return if current_user.present?

        # prevent loop with omniauth endpoints
        return if request.path.start_with?("/auth/")

        auths = Discourse.enabled_authenticators
        return unless auths.size == 1

        provider = auths.first.name

        redirect_to "/auth/#{provider}?prompt=none&origin=#{CGI.escape(request.original_fullpath)}"
      end
    end
  end

  require_dependency "application_controller"
  ::ApplicationController.prepend(::ZeroClickSso::ControllerExtension)
end
