ENV['COCOAPODS_DISABLE_STATS'] = 'true'

target 'ownCloudTests' do
  project 'ownCloud'

  use_frameworks! # Required for Swift Test Targets only
  inherit! :search_paths # Required for not double-linking libraries in the app and test targets.
  pod 'EarlGrey'
end
