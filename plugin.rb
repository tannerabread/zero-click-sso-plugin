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
    Logger = ActiveSupport::Logger.new(Rails.root.join("log", "zero_click_sso.log"))

    module ControllerExtension
      def self.prepended(base)
        base.before_action :zero_click_log_every_request
      end

      private

      def zero_click_log_every_request
        ZeroClickSso::Logger.warn(
          "Zero Click SSO enabled=#{SiteSetting.zero_click_sso_enabled} " \
            "local_logins=#{SiteSetting.enable_local_logins} " \
            "path=#{request.path} format=#{request.format} xhr=#{request.xhr?}",
        )

        return unless SiteSetting.zero_click_sso_enabled
        return if SiteSetting.enable_local_logins
        return unless request.format.html? && !request.xhr?
        return if current_user.present?

        ZeroClickSso::Logger.warn("Future home of SSO probe")
      end
    end
  end

  require_dependency "application_controller"
  ::ApplicationController.prepend(::ZeroClickSso::ControllerExtension)
end
