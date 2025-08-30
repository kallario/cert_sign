# lib/cert_sign/a1_signer.rb
require "hexapdf"

module CertSign
  class A1Signer
    def initialize(key:, cert:, chain: [])
      @key   = key
      @cert  = cert
      @chain = chain
    end

    def self.from_p12(path:, password:)
      p12 = OpenSSL::PKCS12.new(File.binread(path), password)
      new(key: p12.key, cert: p12.certificate, chain: (p12.ca_certs || []))
    end

    # Agora aceita as keywords :signature_type e :tsa_url (e ignora quaisquer outras)
    # visible: { page:, x_pct:, y_pct:, width_pt:, height_pt:, text: }
    def sign_pdf(input_path:, output_path:, visible:, reason: nil, location: nil, contact: nil,
                 signature_type: nil, tsa_url: nil, **_ignored)
      doc = HexaPDF::Document.open(input_path)

      # AcroForm, campo e widget na página desejada
      form = doc.acro_form(create: true)

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
      widget    = sig_field.create_widget(doc.pages[page_index], Rect: rect)

      # === Carimbo visual da assinatura ===
      w = rect[2] - rect[0]
      h = rect[3] - rect[1]
      pad = 6

      #cn    = @cert.subject.to_a.assoc('CN')&..to_s
      cn = @cert.subject.to_s[/CN=([^\/]+)/, 1]
      title = (visible[:text].presence || "Assinado digitalmente").to_s
      now   = Time.now.getlocal.strftime("%d/%m/%Y %H:%M:%S")

      canvas = widget.create_appearance.canvas

      # fundo + borda
      canvas.save_graphics_state do
        canvas.line_width(0.8)
        canvas.stroke_color(0.25)
        canvas.fill_color(0.96)
        canvas.rectangle(0, 0, w, h).fill_stroke
      end

      # título
      y = h - pad - 11
      canvas.fill_color(0)
      canvas.font("Helvetica", variant: :bold, size: 10)
      canvas.text(title, at: [pad, y])
      y -= 14

      # linhas
      canvas.font("Helvetica", size: 9)
      [
        ("Por: #{cn}" unless cn.empty?),
        "Data: #{now}",
        "Motivo: #{(reason || CertSign.config.default_reason)}",
        ("Local: #{(location || CertSign.config.default_location)}" if location || CertSign.config.default_location)
      ].compact.each do |line|
        break if y < pad + 9
        canvas.text(line, at: [pad, y])
        y -= 12
      end
      # === fim do carimbo ===


      # Timestamp handler (opcional)
      ts_handler = nil
      if tsa_url.to_s.strip != ""
        # Em HexaPDF 1.x o helper é exposto via document
        ts_handler = doc.signatures.signing_handler(name: :timestamp, tsa_url: tsa_url) rescue nil
      end

      # Chamada de assinatura (HexaPDF 1.4+)
      # signature_type pode ser :pades (quando quiser PAdES) ou nil (CMS padrão)
      doc.sign(
        output_path,
        signature:         sig_field,
        reason:            reason   || CertSign.config.default_reason,
        location:          location || CertSign.config.default_location,
        contact_info:      contact  || CertSign.config.default_contact,
        certificate:       @cert,
        key:               @key,
        certificate_chain: @chain,
        signature_type:    (signature_type&.to_sym),
        timestamp_handler: ts_handler
      )
    end
  end
end
