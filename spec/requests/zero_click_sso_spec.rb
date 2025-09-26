# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ZeroClickSso Plugin", type: :request do
  before do
    SiteSetting.zero_click_sso_enabled = true
    SiteSetting.enable_local_logins = false
    SiteSetting.enable_local_logins_via_email = false
    SiteSetting.enable_google_oauth2_logins = false
    SiteSetting.enable_github_logins = false

    reset_session if respond_to?(:reset_session)
  end
  it "is enabled site setting" do
    expect(SiteSetting.zero_click_sso_enabled).to be true
  end

  describe "guard conditions" do
    it "does nothing when plugin is disabled" do
      SiteSetting.zero_click_sso_enabled = false
      get "/"
      expect(response).to be_successful
      expect(response).not_to redirect_to(/auth/)
    end

    it "does nothing when local logins enabled" do
      SiteSetting.enable_local_logins = true
      get "/"
      expect(response).to be_successful
      expect(response).not_to redirect_to(/auth/)
    end

    it "does nothing when local email logins enabled" do
      SiteSetting.enable_local_logins = true
      SiteSetting.enable_local_logins_via_email = true
      get "/"
      expect(response).to be_successful
      expect(response).not_to redirect_to(/auth/)
    end

    it "does nothing when user is logged in" do
      user = Fabricate(:user)
      sign_in(user)
      get "/"
      expect(response).to be_successful
      expect(response).not_to redirect_to(/auth/)
    end

    it "does not run on JSON requests" do
      get "/latest.json"
      expect(response).to be_successful
      expect(response).not_to redirect_to(/auth/)
    end

    it "does not redirect on auth callback" do
      get "/auth/google_oauth2/callback"
      expect(response).not_to redirect_to(/auth/)
    end

    it "does nothing if multiple providers are configured" do
      SiteSetting.enable_google_oauth2_logins = true
      SiteSetting.enable_github_logins = true

      get "/"
      expect(response).to be_successful
      expect(response).not_to redirect_to(/auth/)
    end
  end

  describe "zero click login attempt" do
    it "redirects to the provider with prompt=none" do
      SiteSetting.enable_google_oauth2_logins = true
      provider = Discourse.enabled_authenticators.first.name

      get "/"
      expect(response).to redirect_to(%r{auth/#{provider}\?prompt=none&origin=%2F})
    end

    it "does not attempt SSO twice in same session" do
      SiteSetting.enable_google_oauth2_logins = true
      get "/"
      expect(response).to redirect_to(/auth/)
      
      get "/"
      expect(response).to be_successful
      expect(response).not_to redirect_to(/auth/)
    end
  end
end

RSpec.describe ZeroClickSso::FailureHandler do
  def call_handler(path, rack_session: {}, extra_env: {})
    env = Rack::MockRequest.env_for(path, "rack.session" => rack_session).merge(extra_env)
    status, headers, body = described_class.call(env)
    [status, headers, body, env["rack.session"]]
  end

  it "redirects back to origin on silent login_required" do
    status, headers, _body, session =
      call_handler("/auth/failure?prompt=none&error=immediate_failed",
                   rack_session: { zero_click_origin: "/t/123" })

    expect(status).to eq(302)
    expect(headers["location"]).to eq("/t/123")
    expect(session[:zero_click_failed]).to be true
    expect(session[:zero_click_origin]).to be_nil
  end

  it "falls back to default failure handler if not silent" do
    status, headers, _body, _session =
      call_handler("/auth/failure?error=invalid_credentials")

    expect(status).to eq(302)
    expect(headers["location"]).to match(%r{/auth/failure\?message=})
  end
end