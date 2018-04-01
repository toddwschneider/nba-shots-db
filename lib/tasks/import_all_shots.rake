task import_all_shots: :environment do
  Shot.create_all
  ClosestDefenderAggregate.create_all
end
