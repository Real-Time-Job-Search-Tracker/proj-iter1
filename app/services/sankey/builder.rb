# # module Sankey
# #   class Builder
# #     class << self
# #       # Public: build the sankey payload expected by the cucumber steps
# #       # Returns: { nodes: Array<String>, links: { source:, target:, value:, cls: } }
# #       def call(apps)
# #         histories = apps.map(&:history)
# #         current   = apps.map(&:status)

# #         # Build canonical label sequences per app
# #         paths = apps.map { |a| canonical_path(a.history, a.status) }

# #         # Collect nodes (labels) and ensure stable ordering
# #         node_set = Set.new
# #         paths.each { |p| p.each { |lab| node_set << lab } }
# #         nodes = node_set.to_a

# #         # Build link counts between consecutive labels
# #         links = build_links_from_paths(paths, nodes)

# #         { nodes: nodes, links: links }
# #       end

# #       # Label normalization (accept your controller’s mapping)
# #       def stage_label(raw)
# #         ApplicationsController.new.send(:stage_label, raw)
# #       end

# #       # Canonical path (Applications → Applied → … → current), deduping repeats
# #       def canonical_path(history, current_status)
# #         ctl = ApplicationsController.new
# #         ctl.send(:canonical_path, history, current_status)
# #       end

# #       # Same link builder you already prototyped in the controller
# #       def build_links_from_paths(paths, nodes)
# #         ApplicationsController.new.send(:build_links_from_paths, paths, nodes)
# #       end
# #     end
# #   end
# # end

# # app/services/sankey/builder.rb
# module Sankey
#   class Builder
#     def self.call(apps, ghost_days: 14)
#       round_labels = Set.new

#       apps.find_each do |a|
#         Array(a.history).each do |h|
#           lab = stage_label(h["status"])
#           round_labels << lab if lab.start_with?("Round")
#         end
#       end

#       rounds = round_labels.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }
#       nodes = [ "Applications", "Applied" ] + rounds + [ "Offer", "Accepted", "Declined", "Ghosted" ]
#       idx   = nodes.each_with_index.to_h
#       counts = Hash.new(0)
#       klass  = {}

#       add = lambda do |u, v, cls|
#         su, sv = idx[u], idx[v]
#         return unless su && sv
#         key = [ su, sv ]
#         counts[key] += 1
#         klass[key] = cls
#       end

#       apps.find_each do |a|
#         path = canonical_path(a.history, a.status)
#         path.each_cons(2) do |u, v|
#           cls =
#             if u == "Applications" && v.start_with?("Round") then "apps_to_round"
#             elsif u == "Applications" && v == "Ghosted"      then "apps_to_ghosted"
#             elsif u.start_with?("Round") && v.start_with?("Round") then "round_to_round"
#             elsif u.start_with?("Round") && v == "Offer"      then "round_to_offer"
#             elsif u.start_with?("Round") && v == "Ghosted"    then "round_to_ghosted"
#             elsif u == "Offer" && v == "Accepted"             then "offer_to_accepted"
#             elsif u == "Offer" && v == "Declined"             then "offer_to_declined"
#             elsif u == "Offer" && v == "Ghosted"              then "offer_to_ghosted"
#             else "other"
#             end
#           add.call(u, v, cls)
#         end
#       end

#       source, target, value, cls = [], [], [], []
#       counts.each do |(i, j), w|
#         source << i; target << j; value << w; cls << klass[[ i, j ]]
#       end

#       { nodes: nodes, links: { source: source, target: target, value: value, cls: cls } }
#     end

#     def self.stage_label(status)
#       status.to_s.capitalize
#     end
#   end
# end

# app/services/sankey/builder.rb
module Sankey
  class Builder
    def self.call(apps, ghost_days: 14)
      round_labels = Set.new

      apps.find_each do |a|
        Array(a.history).each do |h|
          lab = stage_label(h["status"])
          round_labels << lab if lab.start_with?("Round")
        end
      end

      rounds = round_labels.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }


      nodes = ["Applications", "Applied"] + rounds + ["Offer", "Accepted", "Declined", "Ghosted"]
      idx   = nodes.each_with_index.to_h

      counts = Hash.new(0)
      klass  = {}

      add = lambda do |u, v, cls|
        su, sv = idx[u], idx[v]
        return unless su && sv
        key = [su, sv]
        counts[key] += 1
        klass[key] = cls
      end

      apps.find_each do |a|
        path = canonical_path(a.history, a.status)

        path.each_cons(2) do |u, v|
        cls =
            if u == "Applications" && v == "Applied"               then "apps_to_applied"
            elsif u == "Applications" && v.start_with?("Round")    then "apps_to_round"
            elsif u == "Applications" && v == "Ghosted"            then "apps_to_ghosted"
            elsif u == "Applied" && v.start_with?("Round")         then "applied_to_round"
            elsif u == "Applied" && v == "Offer"                   then "applied_to_offer"
            elsif u == "Applied" && v == "Ghosted"                 then "applied_to_ghosted"
            elsif u.start_with?("Round") && v.start_with?("Round") then "round_to_round"
            elsif u.start_with?("Round") && v == "Offer"           then "round_to_offer"
            elsif u.start_with?("Round") && v == "Ghosted"         then "round_to_ghosted"
            elsif u == "Offer" && v == "Accepted"                  then "offer_to_accepted"
            elsif u == "Offer" && v == "Declined"                  then "offer_to_declined"
            elsif u == "Offer" && v == "Ghosted"                   then "offer_to_ghosted"
            else "other"
            end


          add.call(u, v, cls)
        end
      end

      source, target, value, cls = [], [], [], []
      counts.each do |(i, j), w|
        source << i; target << j; value << w; cls << klass[[i, j]]
      end

      { nodes: nodes, links: { source: source, target: target, value: value, cls: cls } }
    end

    def self.stage_label(status)
      status.to_s.capitalize
    end

    
    def self.canonical_path(history, current_status)
      path = ["Applications"]
      hist = Array(history).map { |h| stage_label(h["status"]) }.compact

      path << "Applied" unless hist.include?("Applied")

      hist.each do |lab|
        next if lab == "Applications"
        path << lab unless path.include?(lab)
      end

      cur = stage_label(current_status)
      if ["Offer", "Accepted", "Declined", "Ghosted"].include?(cur)
        path << cur unless path.last == cur
      end

      path
    end
  end
end
