module ApplicationHelper
    def collect_rounds_from_histories(histories)
        labs = Set.new
        histories.each do |hist|
            Array(hist).each do |h|
                # h might be a hash ({ "status" => ... }) or a plain string ("Round 1 Phone")
                status = h.is_a?(Hash) ? h["status"] : h
                lab = stage_label(status)
                labs << lab if lab.start_with?("Round")
            end
        end
        labs.to_a.sort_by { |x| x[/\d+/].to_i.nonzero? || 1 }
    end
end
