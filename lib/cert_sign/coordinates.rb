# Converte % do canvas para pontos PDF (origem: canto inferior esquerdo do PDF)
module CertSign
  module Coordinates
    module_function

    # x_pct, y_pct ∈ [0,1] (y_pct medido do TOPO do preview)
    # width_pt / height_pt em pontos (1pt = 1/72 pol)
    def rect_from_percent(doc, page_index:, x_pct:, y_pct:, width_pt:, height_pt:)
      page = doc.pages[page_index]
      box  = page.box(:media)
      pdf_w = box.width.to_f
      pdf_h = box.height.to_f

      llx = (x_pct * pdf_w).round(2)
      lly = ((1.0 - y_pct) * pdf_h - height_pt).round(2)
      urx = (llx + width_pt).round(2)
      ury = (lly + height_pt).round(2)

      # Mantém dentro da página
      llx = [[0, llx].max, pdf_w - width_pt].min
      lly = [[0, lly].max, pdf_h - height_pt].min
      urx = llx + width_pt
      ury = lly + height_pt

      [llx, lly, urx, ury]
    end
  end
end
