module VisualizerHelper
  require "dotiw"

  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  def log_duration(log)
    distance_of_time_in_words(log.log_start, log.log_end, compact: true)
  end
end
