module HdWalletCollect
  module Orm
    class Account < ActiveRecord::Base
      self.table_name = 'accounts'
      belongs_to :member
      has_many :payment_addresses
    end
  end
end