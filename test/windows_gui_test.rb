require 'minitest'
require 'minitest/autorun'

require_relative '../lib/windows_gui/common'

class WindowsGUITest < Minitest::Test
  def test_version
    refute_nil WindowsGUI::VERSION
  end
end