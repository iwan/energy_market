module EnergyMarket
  class GroupHash < Hash
    def sum(options={})
      if options[:values]
        case options[:values]
        when :positive, :non_negative
          each_pair{|k,v| self[k]=v.sum_positive}
        when :negative, :non_positive
          each_pair{|k,v| self[k]=v.sum_negative}
        when :zero
          each_pair{|k,v| self[k]=0.0}
        when :all, :non_zero
          each_pair{|k,v| self[k]=v.sum_all}
        else
          raise ArgumentError, "Option not recognized"
        end
      else
        each_pair{|k,v| self[k]=v.sum_all}
      end
    end

    def count(options={})
      if options[:values]
        raise ArgumentError, "Option not recognized" if !%w(positive negative non_positive non_negative non_zero zero all).include?(options[:values].to_s)
        each_pair{|k,v| self[k]=v.send("count_"+options[:values])}
      else
        each_pair{|k,v| self[k]=v.count_all}
      end
    end
  end
end
