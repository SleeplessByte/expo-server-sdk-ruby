# frozen_string_literal: true

require_relative 'lib/expo/server/sdk/version'

Gem::Specification.new do |spec|
  spec.name          = 'expo-server-sdk'
  spec.version       = Expo::Server::SDK::VERSION
  spec.authors       = ['Derk-Jan Karrenbeld']
  spec.email         = ['derk-jan+github@karrenbeld.info']

  spec.summary       = 'Modern replacement for exponent-server-sdk'
  spec.description   = 'This gem has been written to fix shortcomings with the current community provided gem, which ' \
                       'has many outstanding issues and open pull requests.'
  spec.homepage      = 'https://github.com/sleeplessbyte/expo-server-sdk-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'connection_pool', '~> 2.2'
  spec.add_dependency 'http', '>= 4.0', '< 6.0'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
