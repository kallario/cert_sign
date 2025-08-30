# config/initializers/cert_sign.rb
CertSign.configure do |c|
  c.ca_bundle_path  = Rails.root.join("config", "icp_brasil_chain.pem").to_s
  c.tsa_url         = ENV["TSA_URL"].presence
  c.default_reason   = "Assinado eletronicamente"
  c.default_location = "Brasil"
  c.default_contact  = "contato@exemplo.com"
end