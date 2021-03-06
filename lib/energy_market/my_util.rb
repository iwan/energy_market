module EnergyMarket
  module MyUtil
    
    # Return the max value of the arguments
    # Use: max_among(4,9) or max_among(4,9,-6,2)
    def max_among(*arr)
      return nil if arr.nil? || arr.empty?
      arr = arr.first if arr.first.is_a?(Array)
      arr.max
    end

    # Return the min value of the arguments
    # Use: min_among(4,9) or min_among(4,9,-6,2)
    def min_among(*arr)
      return nil if arr.nil? || arr.empty?
      arr = arr.first if arr.first.is_a?(Array)
      arr.min
    end
  end
  
end

# include EnergyMarket::MyUtil

# puts max_among(3.4, 3, 2, 5.8)
# puts max_among()
# puts max_among nil

# puts max_among([3.4, 3, 2, 5.8])
