# frozen_string_literal: true

require 'yaml'

module Settings
  SETTINGS_FILE_NAME = './settings.yml'

  def settings
    @settings ||= YAML.load_file(SETTINGS_FILE_NAME)
  end
end
