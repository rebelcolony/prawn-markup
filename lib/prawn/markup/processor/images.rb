# frozen_string_literal: true

require 'open-uri'

module Prawn
  module Markup
    module Processor::Images
      ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg].freeze

      def self.prepended(base)
        base.known_elements.push('img', 'iframe')
      end

      def start_img
        src = current_attrs['src']
        return if src.to_s.strip.empty?

        add_current_text
        add_image_or_placeholder(src)
      end

      def start_iframe
        placeholder = iframe_placeholder
        append_text("\n#{placeholder}\n") if placeholder
      end

      private

      def add_image_or_placeholder(src)
        img = image_properties(src)
        if img
          add_image(img)
        else
          append_text("\n#{invalid_image_placeholder}\n")
        end
      end

      def add_image(img)
        # parse width in the current context
        # if current_attrs['width']
        #   img[:width] = SizeConverter.new(pdf.bounds.width).parse(current_attrs['width'])
        # else
        #   img[:width] = SizeConverter.new(pdf.bounds.width).parse(style_properties['width'])
        # end
        img[:width] = SizeConverter.new(pdf.bounds.width).parse(current_attrs['width'])
        pdf.image(img.delete(:image), img)
        put_bottom_margin(text_margin_bottom)
      rescue Prawn::Errors::UnsupportedImageType
        append_text("\n#{invalid_image_placeholder}\n")
      end

      def image_properties(src)
        img = load_image(src)
        if img
          props = style_properties
          {
            image: img,
            width: current_attrs['width'],
            position: convert_float_to_position(props['float'])
          }
        end
      end

      def load_image(src)
        custom_load_image(src) ||
          decode_base64_image(src) ||
          load_remote_image(src)
      end

      def custom_load_image(src)
        if options[:image] && options[:image][:loader]
          options[:image][:loader].call(src)
        end
      end

      def decode_base64_image(src)
        match = src.match(/^data:(.*?);(.*?),(.*)$/)
        if match && ALLOWED_IMAGE_TYPES.include?(match[1])
          StringIO.new(Base64.decode64(match[3]))
        end
      end

      def load_remote_image(src)
        if src =~ %r{^https?:/}
          begin
            URI.parse(src).open
          rescue StandardError # OpenURI::HTTPError, SocketError or anything else
            nil
          end
        end
      end

      def convert_float_to_position(float)
        { nil => nil,
          'none' => nil,
          'left' => :left,
          'right' => :right }[float]
      end

      def invalid_image_placeholder
        placeholder_value(%i[image placeholder]) || '[unsupported image]'
      end

      def iframe_placeholder
        placeholder_value(%i[iframe placeholder], current_attrs['src'])
      end
    end
  end
end
