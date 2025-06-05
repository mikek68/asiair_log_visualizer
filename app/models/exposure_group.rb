class ExposureGroup < ApplicationRecord
  belongs_to :shooting_stage

  def duration
    distance_of_time_in_words(run_start, run_end, true, compact: true)
  end

  def successful
    true
  end
end
