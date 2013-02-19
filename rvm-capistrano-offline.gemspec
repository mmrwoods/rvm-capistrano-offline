Gem::Specification.new do |s|
  s.name     = "rvm-capistrano-offline"
  s.version  = "0.0.2"
  s.summary  = "rvm-capistrano behind a bastard firewall"
  s.authors  = "Mark Woods"
  s.homepage = "https://github.com/thickpaddy/rvm-capistrano-offline"
  s.files    = `git ls-files`.split("\n")
  s.license  = 'MIT'

  s.add_dependency 'rvm-capistrano'
end
