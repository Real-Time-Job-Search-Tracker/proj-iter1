module Sankey
  class Builder
    class << self
      # Public: build the sankey payload expected by the cucumber steps
      # Returns: { nodes: Array<String>, links: { source:, target:, value:, cls: } }
      def call(apps)
        histories = apps.map(&:history)
        current   = apps.map(&:status)

        # Build canonical label sequences per app
        paths = apps.map { |a| canonical_path(a.history, a.status) }

        # Collect nodes (labels) and ensure stable ordering
        node_set = Set.new
        paths.each { |p| p.each { |lab| node_set << lab } }
        nodes = node_set.to_a

        # Build link counts between consecutive labels
        links = build_links_from_paths(paths, nodes)

        { nodes: nodes, links: links }
      end

      # Label normalization (accept your controller’s mapping)
      def stage_label(raw)
        ApplicationsController.new.send(:stage_label, raw)
      end

      # Canonical path (Applications → Applied → … → current), deduping repeats
      def canonical_path(history, current_status)
        ctl = ApplicationsController.new
        ctl.send(:canonical_path, history, current_status)
      end

      # Same link builder you already prototyped in the controller
      def build_links_from_paths(paths, nodes)
        ApplicationsController.new.send(:build_links_from_paths, paths, nodes)
      end
    end
  end
end
