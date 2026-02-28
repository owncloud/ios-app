require 'fastlane/action'
require 'spaceship'
require 'fileutils'

module Fastlane
  module Actions
    class UpdateExistingAppsAction < Action
      def self.run(params)
        UI.message("Starting updating Provisioning Profiles.")
        username = UI.input("Please enter your Apple Developer Username:")
        distributionType = params[:TYPE]

        # Login and select team
        Spaceship::Portal.login(username) # Login using the provided username
        Spaceship::Portal.select_team

        # Certificate preparation
        cert = prepareCertificate
        txt_id = ""
        if params[:TXT_ID] != "" 
          txt_id = "#{params[:TXT_ID]}_"
        end

        # Register apps and create provisioning profiles
        prepare_app_id("iOS-App", "App.mobileprovision", params[:APP_ID], params[:APP_ID], cert, distributionType, "BUILD_PROVISION_PROFILE_BASE64_#{txt_id}APP")
        prepare_app_id("File Provider", "FileProvider.mobileprovision", params[:APP_ID], params[:FP_ID], cert, distributionType, "BUILD_PROVISION_PROFILE_BASE64_#{txt_id}FILE_PROVIDER")
        prepare_app_id("File Provider UI", "FileProviderUI.mobileprovision", params[:APP_ID], params[:FP_UI_ID], cert, distributionType, "BUILD_PROVISION_PROFILE_BASE64_#{txt_id}FILE_PROVIDER_UI")
        prepare_app_id("Intent", "Intent.mobileprovision", params[:APP_ID], params[:INTENT_ID], cert, distributionType, "BUILD_PROVISION_PROFILE_BASE64_#{txt_id}INTENT")
        prepare_app_id("ShareExtension", "ShareExtension.mobileprovision", params[:APP_ID], params[:SHARE_EXTENSION_ID], cert, distributionType, "BUILD_PROVISION_PROFILE_BASE64_#{txt_id}SHARE_EXTENSION")
        prepare_app_id("ActionExtension", "ActionExtension.mobileprovision", params[:APP_ID], params[:ACTION_EXTENSION_ID], cert, distributionType, "BUILD_PROVISION_PROFILE_BASE64_#{txt_id}ACTION_EXTENSION")

        UI.message("App Registration Completed")
      end
      
      def self.prepare_app_id(target, profile_filename, app_id, bundle_id, cert, distributionType, txt_id)
        UI.message("Preparing #{target} with bundle ID #{bundle_id}...")

        app = Spaceship::Portal.app.find(bundle_id)
        unless app
          UI.user_error!("App with Bundle ID #{bundle_id} does not exist.")
        end

        prepare_profile(app_id, bundle_id, profile_filename, cert, distributionType, txt_id)
      end

      def self.prepare_profile(app_id, bundle_id, profile_filename, cert, distributionType, txt_id)
      if distributionType == "AppStore"
        profiles = Spaceship::Portal.provisioning_profile.app_store.find_by_bundle_id(bundle_id: bundle_id)
        else 
        profiles = Spaceship::Portal.provisioning_profile.ad_hoc.find_by_bundle_id(bundle_id: bundle_id)
        end
        
        if profiles.count > 0
        if profiles.count == 1
          profile = profiles.first
          UI.message("Using the only available provisioning profile: #{profile.name}")
        else 
          # Display available profiles and prompt user to select one
          UI.message("Multiple provisioning profiles found:")
          profiles.each_with_index do |p, index|
            UI.message("#{index + 1}) #{p.name} (Expires: #{p.expires})")
          end
          
          selected_index = UI.input("Please enter the number of the provisioning profile you want to use:").to_i - 1
          
          # Validate user selection
          if selected_index < 0 || selected_index >= profiles.count
            UI.user_error!("Invalid selection. Please restart and choose a valid provisioning profile.")
          else
            profile = profiles[selected_index]
            UI.message("Using selected provisioning profile: #{profile.name}")
          end
        end
        end

if profile.nil?
if distributionType == "AppStore"
          profile = Spaceship::Portal.provisioning_profile.app_store.create!(bundle_id: bundle_id, certificate: cert, name: "match #{distributionType} #{bundle_id}")
          else
          profile = Spaceship::Portal.provisioning_profile.ad_hoc.create!(bundle_id: bundle_id, certificate: cert, name: "match #{distributionType} #{bundle_id}")
          end
        else 
          # Save the updated profile back to the portal
          profile.update!
          
          UI.message("Successfully updated provisioning profile: #{profile.name}")
        end
        
        # Create the directory structure
        directory_path = "Provisioning_Profiles/#{app_id}/#{distributionType}"
        FileUtils.mkdir_p(directory_path)
        
        # Download the provisioning profile data
        profile_data = profile.download
        
        # Save the profile to the specified directory
        File.write("#{directory_path}/#{profile_filename}", profile_data)
        UI.message("Saved profile for #{bundle_id} to: #{directory_path}/#{profile_filename}")
        
        # Run the base64 command on the profile data and capture the output
        base64_output = IO.popen(["base64"], "r+") do |io|
          io.write(profile_data)
          io.close_write
          io.read
        end
        
        # Save the base64 output to a new file in the same directory
        File.write("#{directory_path}/#{txt_id}.txt", base64_output)
        UI.message("Saved base64-encoded profile to: #{directory_path}/#{txt_id}.txt")
      end
      
      def self.prepareCertificate
        allCerts = []
        
        if Spaceship::Portal.client.in_house?
          allCerts = Spaceship::Portal.certificate.InHouse.all
        else
          allCerts = Spaceship::Portal.certificate.AppleDistribution.all
          if allCerts.count == 0
            allCerts = Spaceship::Portal.certificate.production.all
          end
        end
        
        if allCerts.count == 0
          puts ""
          puts "No certificate found. Proceed with creating a new certificate?"
          puts "1. Yes"
          puts "2. No and exit"
          choose = UI.input("Please enter your value:")
          
          case choose
            when "1"
            create_certificate()
            when "2"
            exit()
            else
              puts "Value is not valid"
              prepareCertificate()
          end
          
        elsif allCerts.count > 0
          puts ""
          puts "Found these certificates on the Developer Portal, please enter the number of the certificate you want to use:"
          index = 1
          for aCert in allCerts
            puts "#{index}) #{aCert.name}\tExpires: #{aCert.expires} (#{aCert.owner_name})"
            index += 1
          end
          puts "N) Create new certificate"
          
          input = UI.input("Please enter your value:")
          
          if input == "N"
            create_certificate()
          else
            cert = allCerts[input.to_i - 1]
          end
        end
        
        return cert
      end
      
      def self.create_certificate
        # Create a new certificate signing request
        csr, pkey = Spaceship.certificate.create_certificate_signing_request
        
        # Use the signing request to create a new distribution certificate
        begin
        certificate = Spaceship::Portal.certificate.AppleDistribution.create!(csr: csr)
        rescue => ex
        distributionType_name = "Distribution"
        if ex.to_s.include?("You already have a current")
          puts "Could not create another #{distributionType_name} certificate, reached the maximum number of available #{distributionType_name} certificates."
          prepareCertificate()
        elsif ex.to_s.include?("You are not allowed to perform this operation.") && distributionType_name == "Distribution"
          puts "You do not have permission to create this certificate. Only Team Admins can create Distribution certificates\n 🔍 See https://developer.apple.com/library/content/documentation/IDEs/Conceptual/AppDistributionGuide/ManagingYourTeam/ManagingYourTeam.html for more information."
          exit()
        end
        raise ex
        end
        
        # Store all that onto the filesystem
        FileUtils.mkdir_p('Provisioning_Profiles')
        request_path = File.expand_path("Provisioning_Profiles/#{certificate.id}.certSigningRequest")
        File.write(request_path, csr.to_pem)
        puts "Saved certificate signing request to: Provisioning_Profiles/#{certificate.id}.certSigningRequest"
        
        private_key_path = File.expand_path("Provisioning_Profiles/#{certificate.id}.p12")
        File.write(private_key_path, pkey)
        puts "Saved certificate private key to: Provisioning_Profiles/#{certificate.id}.p12"
        
        cert_path = store_certificate(certificate)
        
        return cert_path
      end
      
      def self.store_certificate(certificate)
        cert_name = certificate.id
        cert_name = "Provisioning_Profiles/#{cert_name}.cer" unless File.extname(cert_name) == ".cer"
        path = File.expand_path(cert_name)
        raw_data = certificate.download_raw
        File.write(path, raw_data)
        puts "Saved certificate to: Provisioning_Profiles/#{cert_name}.cer"
        puts "Please open the saved certificate and import it into your keychain."          
        input = UI.input("Please press enter after the saved certificate was imported into your keychain.")
        
        return path
      end

      def self.description
        "Registers an existing app with given bundle ID prefix, keychain groups, and creates provisioning profiles"
      end
      
      def self.available_options
      [
        FastlaneCore::ConfigItem.new(key: :DISTRIBUTION_TYPE,
          description: "The provisioning profile distributionType (AppStore, AdHoc)",
          optional: false,
          type: String),
        FastlaneCore::ConfigItem.new(key: :APP_ID,
          description: "The bundle prefix for the app target",
          optional: false,
          type: String),
        FastlaneCore::ConfigItem.new(key: :FP_ID,
          description: "The bundle prefix for the file provider target",
          optional: false,
          type: String),
        FastlaneCore::ConfigItem.new(key: :FP_UI_ID,
          description: "The bundle prefix for the file provider UI target",
          optional: false,
          type: String),
        FastlaneCore::ConfigItem.new(key: :INTENT_ID,
          description: "The bundle prefix for the intent target",
          optional: false,
          type: String),
        FastlaneCore::ConfigItem.new(key: :SHARE_EXTENSION_ID,
          description: "The bundle prefix for the share extension target",
          optional: false,
          type: String),
        FastlaneCore::ConfigItem.new(key: :ACTION_EXTENSION_ID,
          description: "The bundle prefix for the action extension target",
          optional: false,
          type: String),
        FastlaneCore::ConfigItem.new(key: :TXT_ID,
          description: "The file name prefix for the base64 encoded text file",
          optional: false,
          type: String)
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end