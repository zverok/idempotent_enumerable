Gem::Specification.new do |s|
  s.name     = 'times'
  s.version  = '0.0.1'
  s.authors  = ['Victor Shepelev']
  s.email    = 'zverok.offline@gmail.com'
  s.homepage = 'https://github.com/zverok/idempotent_enumerable'

  s.summary = 'Time-related value objects'
  s.description = <<-EOF
    IdempotentEnumerable is like Enumerable, but tries to preserve original collection type when possible.
  EOF
  s.licenses = ['MIT']

  s.required_ruby_version = '>= 2.1.0'

  s.files = `git ls-files`.split($RS).reject do |file|
    file =~ /^(?:
    spec\/.*
    |Gemfile
    |Rakefile
    |\.rspec
    |\.gitignore
    |\.rubocop.yml
    |\.travis.yml
    )$/x
  end
  s.require_paths = ["lib"]

  s.add_development_dependency 'rubocop', '>= 0.50'
  s.add_development_dependency 'rspec', '>= 3'
  s.add_development_dependency 'rubocop-rspec', '>= 1.17.1'
  s.add_development_dependency 'rspec-its', '~> 1'
  s.add_development_dependency 'saharspec', '~> 0.0.2'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubygems-tasks'
  s.add_development_dependency 'yard'
end
