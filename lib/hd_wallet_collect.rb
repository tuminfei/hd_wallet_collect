require 'eth'
require 'bip44'

require 'rails/engine'
require 'hd_wallet_collect/version'
require 'hd_wallet_collect/engine'
require 'hd_wallet_collect/railtie' if defined?(Rails)
require 'hd_wallet_collect/collect_server'

require 'active_record'
require 'hd_wallet_collect/orm/member'
require 'hd_wallet_collect/orm/account'
require 'hd_wallet_collect/orm/payment_address'

require 'hd_wallet_collect/services/infura_client'

require 'yaml'

module HdWalletCollect
  class<< self
    attr_accessor :config, :database_config

    def init_yml=(options = {})
      unless options.empty?
        if options[:collect_config]
          @config = YAML.load(File.open(options[:collect_config]))
        end
        if options[:database_config]
          @database_config = YAML.load(File.open(options[:database_config]))
        end

        #database
        ActiveRecord::Base.establish_connection(
            :adapter  => @database_config['database']['adapter'],
            :host     => @database_config['database']['host'],
            :port     => @database_config['database']['port'],
            :username => @database_config['database']['username'],
            :password => @database_config['database']['password'],
            :database => @database_config['database']['database'],
            :encoding => @database_config['database']['encoding']
        )
      end
    end

  end
end
