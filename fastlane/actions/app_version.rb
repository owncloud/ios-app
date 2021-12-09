module Fastlane
  module Actions
    module SharedValues
      APP_VERSION_CUSTOM_VALUE = :APP_VERSION_VALUE
    end

    class AppVersionAction < Action
      def self.run(params)
        require 'xcodeproj'

        # Load .xcodeproj
        project_path = params[:xcodeproj]
        project = Xcodeproj::Project.open(project_path)

        # Fetch the build configuration objects
        configs = project.objects.select { |obj| obj.isa == 'XCBuildConfiguration'}
        UI.user_error!("Not found XCBuildConfiguration from xcodeproj") unless configs.count > 0

        configs.each do |c|
          if c.build_settings[params[:version_key]] != ''
            app_version = c.build_settings[params[:version_key]]
            UI.success("Found #{params[:version_key]} #{app_version}")
            Actions.lane_context[SharedValues::APP_VERSION_CUSTOM_VALUE] = app_version
            return app_version
          end
        end

        UI.error("Could not found #{params[:version_key]} in XCBuildConfiguration")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Reads the key stored in the Build Configuration"
      end

      def self.details
        "Reads the key stored in the Build Configuration (APP_VERSION, APP_SHORT_VERSION)"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "FL_UPDATE_APPICON_PROJECT_PATH",
                                       description: "Path to your Xcode project",
                                       default_value: Dir['*.xcodeproj'].first,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass the path to the project, not the workspace") unless value.end_with?(".xcodeproj")
                                         UI.user_error!("Could not find Xcode project") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :version_key,
                                       env_name: 'FL_APPVERSION_KEY',
                                       description: 'Key in XCBuildConfiguration for the version string')
        ]
      end

      def self.output
        [
          ['APP_VERSION_CUSTOM_VALUE', 'App Version String e.g. 1.1.2, 154']
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Matthias Hühne"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
