module HdWalletCollect
  module Orm
    class PaymentAddress < ActiveRecord::Base
      self.table_name = 'payment_addresses'
      belongs_to :account
    end
  end
end

