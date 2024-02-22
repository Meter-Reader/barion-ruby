# frozen_string_literal: true

require 'barion/engine' if defined?(Rails::Engine)

# Main module of Barion engine
module Barion
  BASE_URL = {
    test: 'https://api.test.barion.com',
    prod: 'https://api.barion.com'
  }.freeze

  PIXELID_PATTERN = ::Regexp.new('BP-.{10}-\d{2}').freeze

  # rubocop:disable Style/ClassVars
  mattr_accessor :poskey, default: nil
  mattr_accessor :publickey, default: nil
  mattr_accessor :acronym, default: ''
  mattr_accessor :pixel_id, default: ''
  mattr_accessor :sandbox, default: true
  mattr_accessor :default_payee
  mattr_accessor :user_class
  mattr_accessor :item_class
  mattr_accessor :rest_client_class, default: '::RestClient::Resource'

  def self.poskey=(key)
    raise ArgumentError, "::Barion.poskey must be set to a String, got #{key.inspect}" unless key.is_a?(String)

    @@poskey = key
  end

  def self.sandbox?
    sandbox
  end

  def self.sandbox=(val)
    @@sandbox = !!val
  end

  def self.pixel_id=(id)
    raise ArgumentError, "::Barion.pixel_id must be set to a String, got #{id.inspect}" unless id.is_a?(String)

    if PIXELID_PATTERN.match(id).nil?
      raise ::ArgumentError,
            "String:'#{id}' is not in Barion Pixel ID format: 'BP-0000000000-00'"
    end

    @@pixel_id = id
  end

  def self.endpoint
    env = sandbox? ? :test : :prod
    rest_client_class.new BASE_URL[env]
  end

  def self.user_class=(class_name)
    unless class_name.is_a?(String)
      raise ArgumentError, "Barion.user_class must be set to a String, got #{class_name.inspect}"
    end

    @@user_class = class_name
  end

  def self.user_class
    # This is nil before the initializer is installed.
    return nil if @@user_class.nil?

    @@user_class.constantize
  end

  def self.item_class=(class_name)
    unless class_name.is_a?(String)
      raise ArgumentError, "Barion.item_class must be set to a String, got #{class_name.inspect}"
    end

    @@item_class = class_name
  end

  def self.item_class
    # This is nil before the initializer is installed.
    return nil if @@item_class.nil?

    @@item_class.constantize
  end

  def self.rest_client_class
    @@rest_client_class.constantize
  end

  def self.rest_client_class=(class_name)
    unless class_name.is_a?(String)
      raise ArgumentError, "Barion.rest_client_class must be set to a String, got #{class_name.inspect}"
    end

    @@rest_client_class = class_name
  end
  # rubocop:enable Style/ClassVars

  # Error to signal the data in the db has been changed since saving it
  class TamperedData < RuntimeError
  end

  # Generic error class for Barion module
  class Error < StandardError
    attr_reader :title, :error_code, :happened_at, :auth_data, :endpoint, :errors

    def initialize(params)
      @title = params[:Title]
      @error_code = params[:ErrorCode]
      @happened_at = params[:HappenedAt]
      @auth_data = params[:AuthData]
      @endpoint = params[:Endpoint]
      @errors = Array(params[:Errors]).map { |e| Barion::Error.new(e) } if params.key? :Errors
      super(params[:Description])
    end

    def all_errors
      Array(@errors).map(&:message).join("\n")
    end
  end
end
