# frozen_string_literal: true

# name: zero-click-sso
# about: Zero Click SSO Login
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
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
        base.before_action :zero_click_log_every_request
      end

      private

      def zero_click_log_every_request
        return if SiteSetting.enable_local_logins

        Rails.logger.debug(
          "Zero Click SSO: request method=#{request.method} request path=#{request.path}",
        )
      end
    end
  end

  require_dependency "application_controller"
  ::ApplicationController.prepend(::ZeroClickSso::ControllerExtension)
end
