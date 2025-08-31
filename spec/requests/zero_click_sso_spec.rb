# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    SiteSetting.enable_local_logins_via_email = false
    SiteSetting.enable_local_logins = false
    SiteSetting.enable_passkeys = false
    SiteSetting.zero_click_sso_enabled = true
  end
end

RSpec.describe "ZeroClickSso Plugin" do
  before do
    SiteSetting.zero_click_sso_enabled = true
    SiteSetting.enable_local_logins = false
    SiteSetting.enable_google_oauth2_logins = false
    SiteSetting.enable_github_logins = false
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
  end

  it "redirects to the provider with prompt=none" do
    SiteSetting.enable_google_oauth2_logins = true
    provider = Discourse.enabled_authenticators.first.name

    get "/"
    expect(response).to redirect_to(%r{auth/#{provider}\?prompt=none&origin=%2F})
  end

  it "does nothing if multiple providers are configured" do
    SiteSetting.enable_google_oauth2_logins = true
    SiteSetting.enable_github_logins = true

    get "/"
    expect(response).to be_successful
    expect(response).not_to redirect_to(/auth/)
  end

  # TODO: Test the /auth/failure endpoint end to end
  # Request specs are unreliable here due to OmniAuth + bypass middleware intercepting /auth/*
  #   in the test stack
end
