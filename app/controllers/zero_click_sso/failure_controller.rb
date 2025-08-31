# frozen_string_literal: true

module ::ZeroClickSso
  class FailureController < ::ApplicationController
    requires_plugin ZeroClickSso::PLUGIN_NAME
    skip_before_action :verify_authenticity_token

    def index
      Rails.logger.info("Zero Click SSO failure endpoint reached, staying anonymous")
      dest = params[:origin].presence || "/"
      redirect_to dest
    end
  end
end
