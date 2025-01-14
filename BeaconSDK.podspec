Pod::Spec.new do |spec|
  spec.name         = "BeaconSDK"
  spec.version      = "1.1.0"
  spec.summary      = "Beacon is an implementation of the wallet interaction standard tzip-10 which describes the connection of a dApp with a wallet."
  spec.description  = <<-DESC
    Beacon is an implementation of the Tezos wallet interaction standard tzip-10 which describes the connection of a dApp with a wallet.
                   DESC
  spec.homepage     = "https://walletbeacon.io"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Julia Samol" => "j.samol@papers.ch" }
  spec.ios.deployment_target = '13.0'
  spec.source       = { :git => "https://github.com/airgap-it/beacon-ios-sdk.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/**/*.{swift}"
  spec.dependency  'Sodium', '~> 0.9.1'
  spec.dependency  'Base58Swift', '~> 2.1.0'
end
