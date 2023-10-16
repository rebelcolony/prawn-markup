# frozen_string_literal: true

module Prawn
  module Markup
    module Elements
      class Cell < Item
        attr_reader :header, :width, :border_width

        def initialize(header: false, width: 'auto')
          super()
          @header = header
          @width = width
          @border_width = border_width
        end
      end
    end
  end
end
