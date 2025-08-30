# lib/cert_sign/a1_signer.rb
require "hexapdf"

module CertSign
  class A3Signer
    def initialize(key:, cert:, chain: [])
      @key   = key
      @cert  = cert
      @chain = chain
    end

    def self.from_p12(path:, password:)
      p12 = OpenSSL::PKCS12.new(File.binread(path), password)
      new(key: p12.key, cert: p12.certificate, chain: (p12.ca_certs || []))
    end

    # visible: { page:, x_pct:, y_pct:, width_pt:, height_pt:, text: }
    def sign_pdf(input_path:, output_path:, visible:, reason: nil, location: nil, contact: nil, signature_type: nil, tsa_url: nil)
      doc = HexaPDF::Document.open(input_path)

      # 1) cria (ou reusa) o AcroForm
      form = doc.acro_form(create: true)

      # 2) cria o campo de assinatura e o widget na página alvo
      page_index = (visible[:page].to_i - 1).clamp(0, doc.pages.count - 1)
      rect = CertSign::Coordinates.rect_from_percent(
        doc,
        page_index: page_index,
        x_pct:      visible[:x_pct].to_f,
        y_pct:      visible[:y_pct].to_f,
        width_pt:   visible[:width_pt].to_f,
        height_pt:  visible[:height_pt].to_f
      )
      sig_field = form.create_signature_field("Signature#{Time.now.to_i}")
      widget = sig_field.create_widget(doc.pages[page_index], Rect: rect)

      # aparencia simples (texto); você pode desenhar logo/imagem aqui
      widget.create_appearance.canvas.
        font("Helvetica", size: 9).
        text((visible[:text] || "").to_s, at: [4, 4])

      # 3) handler de timestamp (opcional) — estilo 1.4
      ts_handler = nil
      if tsa_url.to_s.present?
        ts_handler = doc.signatures.signing_handler(name: :timestamp, tsa_url: tsa_url)
      end

      # 4) chama o sign – padrão é CMS (adbe.pkcs7.detached). Para PAdES use signature_type: :pades
      doc.sign(output_path,
        signature:          sig_field,
        reason:             (reason   || CertSign.config.default_reason),
        location:           (location || CertSign.config.default_location),
        contact_info:       (contact  || CertSign.config.default_contact),
        certificate:        @cert,
        key:                @key,
        certificate_chain:  @chain,
        signature_type:     (signature_type&.to_sym),   # ex.: :pades ou nil p/ CMS
        timestamp_handler:  ts_handler
      )
    end
  end
end
