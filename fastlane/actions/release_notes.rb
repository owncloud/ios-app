  module Fastlane
  module Actions
    module SharedValues
      RELEASE_NOTES_CUSTOM_VALUE = :RELEASE_NOTES_CUSTOM_VALUE
    end

    class ReleaseNotesAction < Action
      def self.run(params)
        require "plist"
        require 'xcodeproj'

        begin
            # Load .xcodeproj
            project_path = params[:xcodeproj]
            project = Xcodeproj::Project.open(project_path)

            # Fetch the build configuration objects
            configs = project.objects.select { |obj| obj.isa == 'XCBuildConfiguration'}
            UI.user_error!("Not found XCBuildConfiguration from xcodeproj") unless configs.count > 0
            app_version = ''

            configs.each do |c|
              if c.build_settings[params[:version_key]] != ''
                app_version = c.build_settings[params[:version_key]]
                UI.success("Found #{params[:version_key]} #{app_version}")
                break
              end
            end

            # Parse Plist
          path = File.expand_path(params[:path])

          plist = File.open(path) { |f| Plist.parse_xml(f) }
          output = ''
          versions = plist["Versions"]

          versions.each { |item|
            if item["Version"] == app_version
              version = item["ReleaseNotes"]
              UI.success("Found Release Notes for #{app_version}")
              version.each { |subitem|
                output += "• " + subitem["Title"] + "\n" + subitem["Subtitle"] + "\n\n"
              }
            end
          }

          if output != ''
            File.write('fastlane/metadata/en-US/release_notes.txt', output)
          end

          Actions.lane_context[SharedValues::RELEASE_NOTES_CUSTOM_VALUE] = output

          return output
        rescue => ex
          UI.error(ex)
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Reads all release notes for the given version and returns a string"
      end

      def self.details
        "Reads all release notes for the given version and returns a string (VERSION, PLIST_PATH)"
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
                                       description: 'Key in XCBuildConfiguration for the version string'),
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "FL_GET_INFO_PLIST_PATH",
                                       description: "Path to plist file you want to read",
                                       optional: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find plist file at path '#{value}'") unless File.exist?(value)
                                       end)
        ]
      end

      def self.output
        [
          ['RELEASE_NOTES_CUSTOM_VALUE', 'Release Notes String e.g. New Feature: Description']
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
