# Utilise whenever gem
every 1.day, at: '00:00' do
  runner "TrainingSession.create_for_today"
end 