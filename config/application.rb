require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ArquiteturaEstudo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    #
    ## Custom directories with classes and modules you want to be autoloadable.

    Dir["./engines/*"].each do |path|
      next unless File.directory?(path)

      component = path.split("/").last

      config.autoload_paths += Dir[Rails.root.join("engines", component, "app", "**")]
      config.autoload_paths += Dir[Rails.root.join("engines", component, "lib")]

      config.eager_load_paths += Dir[Rails.root.join("engines", component, "app", "**")]
    end
  end
end
