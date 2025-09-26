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
require_relative "lib/zero_click_sso/controller_extension"
require_relative "lib/zero_click_sso/failure_handler"

after_initialize do
  Rails.logger.info("Zero Click SSO plugin initialized")

  require_dependency "application_controller"
  ::ApplicationController.prepend(::ZeroClickSso::ControllerExtension)

  ::OmniAuth.config.on_failure = ::ZeroClickSso::FailureHandler
end
