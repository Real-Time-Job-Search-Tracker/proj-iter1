module Sankey
  class Builder
    def self.call(apps, ghost_days: 14)
      round_labels = Set.new

      # Changed from find_each to each to support both ActiveRecord relations and Arrays
      apps.each do |a|
        Array(a.history).each do |h|
          lab = stage_label(h["status"])
          round_labels << lab if lab.start_with?("Round")
        end
      end

      rounds = round_labels.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }

      # Only include status nodes, no "Applications" node
      all_statuses = [ "Applied" ] + rounds + [ "Interview", "Offer", "Accepted", "Declined", "Ghosted" ]
      nodes = all_statuses.uniq
      idx   = nodes.each_with_index.to_h

      counts = Hash.new(0)
      klass  = {}

      add = lambda do |u, v, cls|
        su, sv = idx[u], idx[v]
        return unless su && sv
        key = [ su, sv ]
        counts[key] += 1
        klass[key] = cls
      end

      # Changed from find_each to each
      apps.each do |a|
        path = canonical_path(a.history, a.status)

        path.each_cons(2) do |u, v|
          # Skip if source is "Applications" (we removed it)
          next if u == "Applications"

          cls =
            if u == "Applied" && v.start_with?("Round")         then "applied_to_round"
            elsif u == "Applied" && v == "Interview"           then "applied_to_interview"
            elsif u == "Applied" && v == "Offer"               then "applied_to_offer"
            elsif u == "Applied" && v == "Ghosted"             then "applied_to_ghosted"
            elsif u.start_with?("Round") && v.start_with?("Round") then "round_to_round"
            elsif u.start_with?("Round") && v == "Interview"   then "round_to_interview"
            elsif u.start_with?("Round") && v == "Offer"       then "round_to_offer"
            elsif u.start_with?("Round") && v == "Ghosted"     then "round_to_ghosted"
            elsif u == "Interview" && v == "Offer"             then "interview_to_offer"
            elsif u == "Interview" && v == "Ghosted"           then "interview_to_ghosted"
            elsif u == "Offer" && v == "Accepted"               then "offer_to_accepted"
            elsif u == "Offer" && v == "Declined"               then "offer_to_declined"
            elsif u == "Offer" && v == "Ghosted"                then "offer_to_ghosted"
            else "other"
            end

          add.call(u, v, cls)
        end
      end

      source, target, value, cls = [], [], [], []
      counts.each do |(i, j), w|
        source << i; target << j; value << w; cls << klass[[ i, j ]]
      end

      { nodes: nodes, links: { source: source, target: target, value: value, cls: cls } }
    end

    def self.stage_label(status)
      status.to_s.capitalize
    end

    def self.canonical_path(history, current_status)
      # Start from Applied, not Applications
      path = []
      hist = Array(history).map { |h| stage_label(h["status"]) }.compact

      # Always start with Applied if not in history
      path << "Applied" unless hist.include?("Applied")

      # Add history statuses in order, avoiding duplicates
      hist.each do |lab|
        next if lab == "Applications" # Skip Applications node
        path << lab unless path.include?(lab)
      end

      # Add current status if it's a final status
      cur = stage_label(current_status)
      if [ "Offer", "Accepted", "Declined", "Ghosted" ].include?(cur)
        path << cur unless path.last == cur
      end

      path
    end
  end
end
