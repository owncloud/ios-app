# Register Script



## Prepare Environement

Before using the script, please run 

```
sudo gem install bundler
```

This will install the Ruby gem  `bundler` which manage all needed dependencies.

After this step is done, please run

```
sudo bundle install --path vendor/bundle
```

in this directory. This will install all needed Ruby libraries into the path `vendor/bundle`.



## Run Register Script

After preparing the environement you can run the script:

```
sudo bundle exec registerOwncloudApp.rb
```

The script will guide you to enter all needed values to setup all informations to register all targets for the ownCloud app to your Apple Developer account.



## Cleanup

After the registration is done, the created folder `Asssets` and `vendor` can be deleted.

Please note, that the folder `Assets` could contain the private key for a newly created signing certificate. Please store this file into a secure folder or delete the file.

Provisioning Profiles will be stored in the folder `../resign/Provisioning Files` and should be kept for resigning the ownCloud binary file (`IPA`).

