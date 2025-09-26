# frozen_string_literal: true

module ::ZeroClickSso
  class FailureHandler
    def self.call(env)
      request = ActionDispatch::Request.new(env)
      session = request.session

      if request.params["prompt"] == "none" || session[:zero_click_attempted]
        origin = session[:zero_click_origin] || env['omniauth.origin'] || "#{GlobalSetting.relative_url_root}/"

        session[:zero_click_failed] = true
        session.delete(:zero_click_origin)

        if request.params["error"] == "immediate_failed" || request.params["error_subtype"] == "login_required"
          return [302, { "location" => origin }, ["Redirecting..."]]
        end
      end

      ::OmniAuth::FailureEndpoint.call(env)
    end
  end
end