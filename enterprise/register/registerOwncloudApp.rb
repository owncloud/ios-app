#!/usr/bin/env ruby

require 'spaceship'

class AppRegistration
	
	def getRegistrationType()
		puts ""
		puts "Do you want to use an existing app or create an new app?"
		puts "1. Use Existing App"
		puts "2. Create new App and use suggested bundle IDs"
		puts "3. Create new App and enter custom bundle IDs"
		puts "4. Download Provisioning Profiles for existing bundle IDs"
		
		choose = gets.chomp
		
		case choose
		  	when "1"
				registrationType = :existing
		    when "2"
				registrationType = :suggested
			when "3"
				registrationType = :custom
			when "4"
				registrationType = :download
			else
				puts "Value is not valid"
				getRegistrationType()
		end
		
		return registrationType
	end
	
	def getKeychainGroup()
		groups = []
		puts ""
		puts "Do you want to use an existing keychain group or create a new keychain group?"
		puts "1. Use Existing Keychain Group"
		puts "2. Create new Keychain Group"
		
		choose = gets.chomp
		
		case choose
		  when "1"
		  groups = keychainGroups()
		  when "2"
			puts "Enter a keychain group id (eg.group.com.yourcompany.ios-app)"
			newGroupID = gets.chomp
			puts "Enter a keychain group name (eg. Sample Name)"
			newGroupName = gets.chomp
		    group = Spaceship::Portal.app_group.create!(group_id: newGroupID, name: newGroupName)
		    groups = [group]
		  else
			puts "Value is not valid"
			getKeychainGroup()
		end	
		
		return groups
	end
	
	def getBundlePrefix()
		puts "Please enter a bundle ID prefix (e.g. com.yourcompany.ios-app). We will automatically append a prefix for every target."
		bundlePrefix = gets.chomp
	end
	
	def prepareCertificate()
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
			choose = gets.chomp
			
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
			
			input = gets.chomp
			
			if input == "N"
				create_certificate()
			else
				cert = allCerts[input.to_i - 1]
			end
		end
		
		return cert
	end
	
	def create_certificate
	  # Create a new certificate signing request
	  csr, pkey = Spaceship.certificate.create_certificate_signing_request

	  # Use the signing request to create a new distribution certificate
	  begin
		certificate = Spaceship::Portal.certificate.production.create!(csr: csr)
	  rescue => ex
		type_name = "Distribution"
		if ex.to_s.include?("You already have a current")
		  puts "Could not create another #{type_name} certificate, reached the maximum number of available #{type_name} certificates."
		  prepareCertificate()
		elsif ex.to_s.include?("You are not allowed to perform this operation.") && type_name == "Distribution"
		  puts "You do not have permission to create this certificate. Only Team Admins can create Distribution certificates\n 🔍 See https://developer.apple.com/library/content/documentation/IDEs/Conceptual/AppDistributionGuide/ManagingYourTeam/ManagingYourTeam.html for more information."
		  exit()
		end
		raise ex
	  end

	  # Store all that onto the filesystem
	  request_path = File.expand_path("Assets/#{certificate.id}.certSigningRequest")
	  File.write(request_path, csr.to_pem)
	  puts "Saved certificate signing request to: Assets/#{certificate.id}.certSigningRequest"

	  private_key_path = File.expand_path("Assets/#{certificate.id}.p12")
	  File.write(private_key_path, pkey)
	  puts "Saved certificate private key to: Assets/#{certificate.id}.p12"

	  cert_path = store_certificate(certificate)

	  return cert_path
	end

	def store_certificate(certificate)
	  cert_name = certificate.id
	  cert_name = "Assets/#{cert_name}.cer" unless File.extname(cert_name) == ".cer"
	  path = File.expand_path(cert_name)
	  raw_data = certificate.download_raw
	  File.write(path, raw_data)
	  puts "Saved certificate to: Assets/#{cert_name}.cer"
	  puts "Please open the saved certificate and import it into your keychain."
		
	  return path
	end
	
	
	def keychainGroups
		groups = []
		all_groups = Spaceship::Portal.app_group.all
		if all_groups.count > 0 
			puts ""
			puts "Multiple Keychain Groups found on the Developer Portal, please enter the number of the Keychain group you want to use:"
			index = 1
			for aGroup in all_groups
				puts "#{index}) #{aGroup.name}\tID: #{aGroup.group_id}"
				index += 1
			end
		
			input = gets.chomp
			groups << all_groups[input.to_i - 1]
		elsif all_groups.count == 0
			groups << all_groups.first
		else
			puts ""
			puts "No Keychain Groups available! Please enter the ID of the new keychain group (e.g. group.com.yourcompany.ios-app)"
			groupID = gets.chomp
			puts "Please enter the name of the new keychain group (e.g. Sample Keychain Group)"
			groupName = gets.chomp
			groups << Spaceship::Portal.app_group.create!(group_id: groupID,
			name: groupName)
		end
		
		return groups
	end
	
	
	def prepareAppID(target, profileFilename, groups, registrationType, suggestedBundleID, cert)
		if registrationType == :suggested
			bundle_id = suggestedBundleID
		else
			puts ""
			puts "Please enter the Bundle ID for the target #{target}:"
			bundle_id = gets.chomp
		end
		
		puts "Preparing #{bundle_id}…"
		if bundle_id.empty?
			prepareAppID(target, profileFilename, groups, registrationType, suggestedBundleID)
		elsif registrationType != :download
			app = Spaceship::Portal.app.find(bundle_id)
			
			if registrationType != :existing && app
				puts ""
				abort("You chose to create a new Bundle ID, but the given Bundle ID #{bundle_id} already exists. Please restart the script an enter a new Bundle ID.")
			elsif registrationType == :existing && !app
				puts "The entered Bundle ID does not exist. Creating a new App with the given Bundle ID."
				prepareAppID(target, profileFilename, groups, :suggested, bundle_id, cert)
				return
			end
			
			if !app
				puts ""
				puts("App does not exist. Creating a new app…")
				app = Spaceship::Portal.app.create!(bundle_id: bundle_id, name: "ownCloud Target #{target}")
			end
			app = app.update_service(Spaceship::Portal.app_service.associated_domains.on)
			app = app.update_service(Spaceship::Portal.app_service.app_group.on)
			app = app.associate_groups(groups)
		end
	
		prepareProfile(bundle_id, profileFilename, cert)
	end
	
	def prepareProfile(bundle_id, profileFilename, cert)
		if Spaceship::Portal.client.in_house?
			filtered_profiles = Spaceship::Portal.provisioning_profile.InHouse.find_by_bundle_id(bundle_id: bundle_id)
		else
			filtered_profiles = Spaceship::Portal.provisioning_profile.app_store.find_by_bundle_id(bundle_id: bundle_id)
		end
		
		if filtered_profiles.count == 0 
			puts "Profile does not exist, create new Profile…"
			
			if Spaceship::Portal.client.in_house?
				profile = Spaceship::Portal.provisioning_profile.InHouse.create!(bundle_id: bundle_id, certificate: cert,  name: "match InHouse #{bundle_id}")
			else
				profile = Spaceship::Portal.provisioning_profile.app_store.create!(bundle_id: bundle_id, certificate: cert,  name: "match AppStore #{bundle_id}")
			end
		else
			profile = filtered_profiles.first
			
			if !profile.valid?
				puts "Repairing Profile…"
				profile.repair!
				
				if Spaceship::Portal.client.in_house?
					filtered_profiles = Spaceship::Portal.provisioning_profile.InHouse.find_by_bundle_id(bundle_id: bundle_id)
				else
					filtered_profiles = Spaceship::Portal.provisioning_profile.app_store.find_by_bundle_id(bundle_id: bundle_id)
				end
				profile = filtered_profiles.first
			end
		end
		
		profileData = profile.download
		if !profileData.empty?
			if !Dir.exist?("Assets")
				Dir.mkdir "Assets"
			end
			File.write("Assets/#{profileFilename}", profileData)
			puts "Saved profile for #{bundle_id} to: Assets/#{profileFilename}"
		
			if Dir.exist?("../resign/Provisioning Files/")
				File.write("../resign/Provisioning Files/#{profileFilename}", profile.download)
				puts "Saved profile for #{bundle_id} to: ../resign/Provisioning Files/#{profileFilename}"
			end
		end
	end

end


# Begin registration process
Spaceship::Portal.login()
Spaceship::Portal.select_team

register = AppRegistration. new

# Choose the certificate to use
cert = register.prepareCertificate()

# Choose app registration type
registrationType = register.getRegistrationType()

# Get bundle prefix for suggested App IDs
if registrationType == :suggested
	bundlePrefix = register.getBundlePrefix()
end

# Choose keychain group
if registrationType != :download
	groups = register.getKeychainGroup()
end

# Prepare App IDs and Provisioning Profiles
register.prepareAppID("iOS-App", "App.mobileprovision", groups, registrationType, "#{bundlePrefix}.ios-app", cert)
register.prepareAppID("File Provider", "FileProvider.mobileprovision", groups,registrationType, "#{bundlePrefix}.ios-app.ownCloud-File-Provider", cert)
register.prepareAppID("File Provider UI", "FileProviderUI.mobileprovision", groups, registrationType, "#{bundlePrefix}.ios-app.ownCloud-File-ProviderUI", cert)
register.prepareAppID("Intent", "Intent.mobileprovision", groups, registrationType, "#{bundlePrefix}.ios-app.ownCloud-Intent", cert)
register.prepareAppID("ShareExtension", "ShareExtension.mobileprovision", groups, registrationType,"#{bundlePrefix}.ios-app.ownCloud-Share-Extension", cert)
