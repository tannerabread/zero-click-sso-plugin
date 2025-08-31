# frozen_string_literal: true

module ::ZeroClickSso
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace ZeroClickSso
    config.autoload_paths << File.join(config.root, "lib")
    scheduled_job_dir = "#{config.root}/app/jobs/scheduled"
    config.to_prepare do
      Rails.autoloaders.main.eager_load_dir(scheduled_job_dir) if Dir.exist?(scheduled_job_dir)
    end
  end
end

ZeroClickSso::Engine.routes.draw { get "/failure", to: "failure#index" }

Discourse::Application.routes.append do
  mount ::ZeroClickSso::Engine, at: "/auth", as: "zero_click_sso_plugin"
end
