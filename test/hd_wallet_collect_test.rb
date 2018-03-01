require "test_helper"

class HdWalletCollectTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::HdWalletCollect::VERSION
  end

  def test_load_file
    HdWalletCollect.collect_yml = {
        :file_bots => File.join('~/RubymineProjects/hd_wallet_collect/config', 'collect_config.yml'),
    }
  end
end
