# frozen_string_literal: true

require 'addressable/uri'
require 'resolv'

module ActiveModel
  module Validations
    class UrlValidator < ActiveModel::EachValidator
      domain = YAML.safe_load File.read(File.dirname(__FILE__) + '/valid_url/config/domain.yml')

      PROTOCOLS = domain['protocols']
      ZONES = domain['zones']

      def validate_each(record, attribute, value)
        begin
          url = ensure_protocol(value)
          uri = Addressable::URI.parse(url)
        rescue StandardError
          invalid = true
        end

        record.errors[attribute] << (options[:message] || 'is an invalid URL') unless !invalid && valid_scheme?(uri.scheme) && valid_host?(uri.host) && valid_path?(uri.path)
      end

      protected

      # add common protocol by default
      def ensure_protocol(url)
        if url[%r{\A(http|https)://}i]
          url
        else
          'http://' + url
        end
      end

      # http and https are accepted
      def valid_scheme?(scheme)
        UrlValidator::PROTOCOLS.include?(scheme.mb_chars.downcase.to_s)
      end

      def valid_host?(host)
        return false unless host.present? && valid_characters?(host)

        labels = host.split('.')
        valid_length?(host) && valid_labels?(labels) && (valid_ip?(host) || valid_zone?(labels.last))
      end

      # each label must be between 1 and 63 characters long
      def valid_labels?(labels)
        labels.count >= 2 && labels.all? { |label| label.length >= 1 && label.length <= 63 }
      end

      # entire hostname has a maximum of 253 characters
      def valid_length?(host)
        host.length <= 253
      end

      # only existent domain name zones
      def valid_zone?(zone)
        UrlValidator::ZONES.include?(zone.mb_chars.downcase.to_s)
      end

      # check if host is an ip-address
      def valid_ip?(host)
        host =~ Resolv::IPv4::Regex
      end

      # disallow some prohibited characters
      def valid_characters?(host)
        !host[%r{[\s\!\\"$%&'\(\)*+_,:;<=>?@\[\]^|£§°ç/]}] && host.last != '.'
      end

      # disallow blank caracters in the path
      def valid_path?(path)
        !path[/\s/]
      end
    end
  end
end
