module EnergyMarket
  module ArrayMethods
    module InstanceMethods
      def sum_all
        inject(0.0){|total, n| total + (n||0.0) }
      end

      def sum_positive
        inject(0.0){|total, n| total + (n>0.0 ? n : 0.0) }
      end

      def sum_negative
        inject(0.0){|total, n| total + (n<0.0 ? n : 0.0) }
      end

      def count_positive
        count{|e| e>0.0}
      end

      def count_non_positive
        count{|e| e<=0.0}
      end

      def count_non_negative
        count{|e| e>=0.0}
      end

      def count_negative
        count{|e| e<0.0}
      end

      def count_non_zero
        count{|e| e!=0.0}
      end

      def count_zero
        count{|e| e==0.0}
      end

      def count_all
        size
      end
    end
    
    def self.included(receiver)
      receiver.send :include, InstanceMethods
    end
  end  
end
