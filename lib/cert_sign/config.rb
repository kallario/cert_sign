module CertSign
  class Config
    attr_accessor :ca_bundle_path, :tsa_url, :default_reason, :default_location, :default_contact

    def initialize
      @ca_bundle_path   = nil
      @tsa_url          = nil
      @default_reason   = "Assinatura eletrônica"
      @default_location = "Brasil"
      @default_contact  = ""
    end
  end

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end
end

