require 'rufus-scheduler'

module HdWalletCollect
  class CollectServer
    attr_accessor :scheduler, :infura

    def initialize

      scheduler = Rufus::Scheduler.new

      @infura = HdWalletCollect::Services::InfuraClient.new

      config = HdWalletCollect.config
      when_ever = config['scheduler_params']['when_ever']
      eth_seed = config['wallet_params']['eth_seed']

      scheduler.every when_ever||'3s', :tag => config['scheduler_name'], :blocking => true do
        puts 'Hello... HD Wallet Collect'

        eth_currency_id = config['collect_params']['eth_currency_id']
        eth_min_amount = config['collect_params']['min_eth_amout']
        xprv = config['wallet_params']['wallet_xprv']
        eth_gas_limit = config['collect_params']['fill_gas_limit']
        eth_gas_price = config['collect_params']['fill_gas_price']
        hold_eth_amount = config['collect_params']['hold_eth_amount']

        user_ids = []

        #先归集ERC20币
        currency_codes = config['collect_erc20']
        currency_codes.each do |currency|
          currency_limit = currency['collect_amount']
          gas_limit = currency['gas_limit']
          gas_price = currency['gas_price']

          wallets = HdWalletCollect::Orm::PaymentAddress.where(["currency = ? and balance >= ? and collect_at is null", currency_id, currency_limit])
          wallets.each do |payment_address|
            # 计算私钥
            wallet = Bip44::Wallet.from_xprv(xprv)
            sub_wallet = wallet.sub_wallet("m/#{payment_address.account.member_id}")
            sub_address = sub_wallet.ethereum_address
            sub_key = sub_wallet.private_key

            token_balance = @infura.get_token_balance(sub_address, currency['token_address'], currency['token_decimals'])
            puts "----sweep address: #{sub_address}, token_balance: #{token_balance}, sweep_limit: #{BigDecimal(currency_limit)}"

            # 如果归集到达归集数量
            if token_balance >= BigDecimal(currency_limit)
              payment_address.update_attribute(:collect_at, Time.now)
              puts ".."

              # 1. 填充eth
              fill_txid = fill_eth(config['collect_params']['fill_eth_from_private_key'], sub_address, gas_limit, gas_price, eth_gas_limit, eth_gas_price)
              if fill_txid
                puts "  1. fill eth: #{fill_txid}"
                @infura.wait_for_miner(fill_txid)
              end

              # 2. sweep coin
              sweep_txid = wallet_collect(currency, sub_key)
              if sweep_txid
                puts "  2. sweep coin: #{sweep_txid}"
                @infura.wait_for_miner(sweep_txid)
              end

              # 3. 归集ETH
              sweep_eth_txid = sweep_eth(sub_key, sub_address, currency['collect_address'], hold_eth_amount, eth_gas_limit, eth_gas_price)
              if sweep_eth_txid
                puts "  3. sweep eth: #{sweep_eth_txid}"
                @infura.wait_for_miner(sweep_eth_txid)
              end
            end

          end

          user_ids.each do |u_id|
              # 计算私钥
              wallet = Bip44::Wallet.from_xprv(xprv)
              sub_wallet = wallet.sub_wallet("m/#{u_id}")
              sub_address = sub_wallet.ethereum_address
              sub_key = sub_wallet.private_key

              token_balance = @infura.get_token_balance(sub_address, currency['token_address'], currency['token_decimals'])
              puts "----sweep address: #{sub_address}, token_balance: #{token_balance}, sweep_limit: #{BigDecimal(currency_limit)}"

              # 如果归集到达归集数量
              if token_balance >= BigDecimal(currency_limit)
                # 1. 填充eth
                fill_txid = fill_eth(config['collect_params']['fill_eth_from_private_key'], sub_address, gas_limit, gas_price, eth_gas_limit, eth_gas_price)
                if fill_txid
                  puts "  1. fill eth: #{fill_txid}"
                  @infura.wait_for_miner(fill_txid)
                end

                # 2. sweep coin
                sweep_txid = wallet_collect(currency, sub_key)
                if sweep_txid
                  puts "  2. sweep coin: #{sweep_txid}"
                  @infura.wait_for_miner(sweep_txid)
                end

                # 3. 归集ETH
                sweep_eth_txid = sweep_eth(sub_key, sub_address, currency['collect_address'], hold_eth_amount, eth_gas_limit, eth_gas_price)
                if sweep_eth_txid
                  puts "  3. sweep eth: #{sweep_eth_txid}"
                  @infura.wait_for_miner(sweep_eth_txid)
                end
              end
          end
        end
      end
    end

    def fill_eth(private_key, to, gas_limit, gas_price, fill_gas_limit, fill_gas_price)
      # 目标地址上现有eth
      eth_balance = @infura.get_eth_balance(to)
      # 目标地址上需要填充满这么多eth
      amount = BigDecimal(gas_limit) * BigDecimal(gas_price) / 10**18
      return nil unless eth_balance < amount
      rawtx = @infura.generate_raw_transaction(private_key, (amount - eth_balance), nil, fill_gas_limit, fill_gas_price, to)
      txid = @infura.eth_send_raw_transaction(rawtx)
      return txid
    end

    def wallet_collect(currency, private_key)
      #余额查询
      address = ::Eth::Key.new(priv: private_key).address
      token_balance = @infura.get_token_balance(address, currency['token_address'], currency['token_decimals'])
      return nil if token_balance == 0

      tx_id = @infura.transfer_token(private_key, currency['token_address'], currency['token_decimals'], token_balance,currency['gas_limit'], currency['gas_price'], currency['collect_address'])
      return tx_id
    end

    def sweep_eth(private_key, from, to, min_eth_amout, fill_gas_limit, fill_gas_price)
      # 目标地址上现有eth
      eth_balance = @infura.get_eth_balance(from)
      # 归集花费金额
      sweep_amount = BigDecimal(fill_gas_limit) * BigDecimal(fill_gas_price) / BigDecimal(10**18)

      return nil if eth_balance < min_eth_amout
      rawtx = @infura.generate_raw_transaction(private_key, (eth_balance - sweep_amount), nil, fill_gas_limit, fill_gas_price, to)
      txid = @infura.eth_send_raw_transaction(rawtx)
      return txid
    end

    def run!
      while true
        puts ".."
        sleep(2)
      end
    end
  end
end