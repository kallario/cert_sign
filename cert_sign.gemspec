# cert_sign.gemspec
require_relative "lib/cert_sign/version"

Gem::Specification.new do |s|
  s.name        = "cert_sign"
  s.version     = CertSign::VERSION
  s.summary     = "Assinatura digital PAdES (PDF) com certificado A1/A3 (ICP-Brasil pronto)."
  s.description = "Assine PDFs em Ruby/Rails usando HexaPDF. Preview no browser, marcação do local e assinatura PAdES."
  s.authors     = ["Luiz Cláudio de Castro Figueredo"]
  s.email       = ["luizfigueredo@gmail.com"]
  s.files       = Dir["lib/**/*"]
  s.homepage    = "https://github.com/luizclaudiocfigueredo"
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.0"

  s.add_dependency "hexapdf", ">= 0.41"
  s.add_dependency "openssl" # stdlib, mas declaramos
  s.add_development_dependency "rake"
end
