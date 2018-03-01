module HdWalletCollect
  module Orm
    class Member < ActiveRecord::Base
      self.table_name = 'members'
      has_many :accounts
    end
  end
end


