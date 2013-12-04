require 'active_support/core_ext/time/zones'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/numeric/time'

module EnergyMarket
  
  class Vector
    attr_reader :start_time, :v, :step
    @@valid_units = [:hour, :day, :month, :year]


    def initialize(start_time=nil, options={})
      options = {:zone => get_current_time_zone, :unit => :hour}.merge(options)
      Time.zone = options[:zone]
      @start_time = floor_start_time(read_start_time(start_time), options[:unit])
      @v = ValuesArray.new
    end


    # Clone the current object
    def clone
      Vector.new(@start_time).data(@v.clone)
    end


    # Set the array of values. You can define the unit (granularity) of those data.
    # By default the unit is :hour
    def data(data, unit=:hour)
      unit = unit.to_sym
      data = [data] unless data.is_a? Array
      @v = ValuesArray.new
      validate_unit unit
      start_time = @start_time.clone

      # the values are always stored as hour values
      if unit==:hour
        @v = data
      else
        prev_value = start_time.send(unit)
        data.each do |v|
          while start_time.send(unit)==prev_value
            @v << v
            start_time+=1.hour
          end
          prev_value = start_time.send(unit)
        end
      end
      self
    end


    def set_all_to(value)
      @v = @v.map{|e| e=value}
    end


    # get the sum of the values
    def sum(options = {})
      if options[:values]
        case options[:values]
        when :positive, :not_negative
          @v.inject(0.0){|total, n| total + (n>0.0 ? n : 0.0) }
        when :negative, :not_positive
          @v.inject(0.0){|total, n| total + (n<0.0 ? n : 0.0) }
        when :zero
          0.0
        when :all, :not_zero
          sum_all_elements  
        else
          raise ArgumentError, "Option not recognized"
        end
      else
        sum_all_elements
      end
    end


    # Count the values
    def count(options = {})
      if options[:values]
        case options[:values]
        when :positive
          @v.inject(0){|total, n| total + (n>0.0 ? 1 : 0) }
        when :negative
          @v.inject(0){|total, n| total + (n<0.0 ? 1 : 0) }
        when :not_positive
          @v.inject(0){|total, n| total + (n<=0.0 ? 1 : 0) }
        when :not_negative
          @v.inject(0){|total, n| total + (n>=0.0 ? 1 : 0) }
        when :not_zero
          @v.inject(0.0){|total, n| total + (n!=0.0 ? 1 : 0) }
        when :zero
          @v.inject(0){|total, n| total + (n==0.0 ? 1 : 0) }
        when :all
          count_all_elements
        else
          raise ArgumentError, "Option not recognized"
        end
      else
        count_all_elements
      end
    end
    # alias :size :count


    # Return the mean of values
    def mean(options = {})
      c = count(options)
      return nil if c.zero? # if the array is empty will be returned nil
      sum(options) / c
    end


    def minimum_value
      @v.compact.min
    rescue
      nil
    end

    def maximum_value
      @v.compact.max
    rescue
      nil
    end


    def round!(ndigit=3)
      @v.collect!{|e| e.nil? ? nil : e.round(ndigit)}
    end


    # Return an array with two objects:
    # - an array of HourNumber element (one HourNumber for each hour). The hours are not necessarily consecutive 
    # - an array of values (float or integers) (one HourNumber for each hour). The hours are not necessarily consecutive 
    def xy_array(options={})

      values=[]
      if options[:values]
        case options[:values]
        when :positive
          values = @v.collect{|v| v if v>0.0}
        when :negative
          values = @v.collect{|v| v if v<0.0}
        when :not_positive
          values = @v.collect{|v| v if v<=0.0}
        when :not_negative
          values = @v.collect{|v| v if v>=0.0}
        when :not_zero
          values = @v.collect{|v| v if v!=0.0}
        when :zero
          values = @v.collect{|v| v if v==0.0}
        when :all
          values = @v.clone
        else
          raise ArgumentError, "Option not recognized"
        end
      else
        # return [hour_numbers, @v]
        values = @v.clone
      end
      hn = Array.new(@v.size, @start_time)
      @v.size.times do |i|
        if values[i].nil?
          hn[i] = nil
        else
          hn[i]+=i.hours
        end
      end
      [hn.compact, values.compact]
    end


    def end_time
      return nil if empty?
      # return @start_time if @v.empty?
      @start_time + (@v.size-1).hours
    end

    def empty?
      @v.empty?
    end

    def aligned_with?(v)
      self.start_time==v.start_time && @v.size==v.size
    end
  
    def align_with(v)
      s = [start_time, v.start_time].max
      if end_time && v.end_time
        e = [end_time, v.end_time].min
        if s <= e
          @v = @v[((s-start_time)/3600).to_i, 1+((e-s)/3600).to_i]
        else
          @v = []
        end
      else
        @v = []
      end
      @start_time = s       
    end


    # intersection
    def align_with_old(vector_2)
      s1, s2 = @start_time, vector_2.start_time
      return nil if s1==s2 && @v.size==vector_2.size
      e1, e2 = self.end_time, vector_2.end_time

      if e1 && e2 # values are not empties
        ks = [0, ((s2-s1)/3600).to_i].max
        ke = [0, ((e2-e1)/3600).to_i].min
        puts "----> ks: #{ks} - ke: #{ke}"
        @v = @v[ks..(ke-1)]
      else
        @v = []
      end
      @start_time = (s1>s2 ? s1 : s2)
    end


    def size
      @v.size
    end

    def to_s
      "Start time: #{@start_time}\nData (size: #{@v.size}):\n#{print_values}"
    end

    def print_values
      start_time = @start_time - 1.hour
      @v.collect{|v| "#{(start_time+=1.hour).strftime('%Y-%m-%d %H:%M %a')}\t#{v}" }.join("\n")
    end

    def until_the_end_of_the_year(fill_value=0.0)
      t = Time.zone.parse("#{@start_time.year+1}-01-01")
      hh = (t-@start_time)/( 60 * 60) # final size
      @v += ValuesArray.new(hh-@v.size, fill_value) if hh>@v.size
      self
    end

    def +(vec)
      return self if vec.nil?
      c = self.clone
      if vec.is_a? Numeric # Fixnum or Float...
        default_value = vec
      else
        c.align_with(vec)
      end

      c.size.times do |i|
        c.set_value(i, c.value(i)+(default_value || vec.value(i) || 0.0))
      end
      c
    end

    def -(vec)
      return self if vec.nil?
      c = self.clone
      if vec.is_a? Numeric # Fixnum or Float...
        default_value = vec
      else
        c.align_with(vec)
      end
      c.size.times do |i|
        c.set_value(i, c.value(i)-(default_value || vec.value(i) || 0.0))
      end
      c
    end

    def *(vec)
      return self if vec.nil?
      c = self.clone
      if vec.is_a? Numeric # Fixnum or Float...
        default_value = vec
      else
        c.align_with(vec)
      end
      c.size.times do |i|
        c.set_value(i, c.value(i)*(default_value || vec.value(i) || 1.0))
      end
      c
    end

    def /(vec)
      return self if vec.nil?
      c = self.clone
      if vec.is_a? Numeric # Fixnum or Float...
        default_value = vec
      else
        c.align_with(vec)
      end
      c.size.times do |i|
        c.set_value(i, c.value(i).to_f/(default_value || vec.value(i) || 1.0))
      end
      c
    end

    # v1.max(v2) return a new obj where which element is the max between the elements of v1 and v2
    # v2 can also be of type Numeric
    def max(vec=0.0)
      return self if vec.nil?
      c = self.clone
      if vec.is_a? Numeric # Fixnum or Float...
        default_value = vec
      else
        c.align_with(vec)
      end
      c.size.times do |i|
        c.set_value(i, max_among(c.value(i),  default_value || vec.value(i)))
      end
      c
    end

    def min(vec=0.0)
      return self if vec.nil?
      c = self.clone
      if vec.is_a? Numeric # Fixnum or Float...
        default_value = vec
      else
        c.align_with(vec)
      end
      c.size.times do |i|
        c.set_value(i, min_among(c.value(i),  default_value || vec.value(i)))
      end
      c
    end

    def value(index)
      @v[index]
    end

    def first_values(number)
      @v[0,number]
    end
    def set_value(index, v)
      @v[index]=v
    end


    private

    def floor_start_time(t, unit=:hour)
      case unit
      # when :'15minutes'
      #   t = t - t.sec - (60 * (t.min % 15)) # floor to hour
      when :hour
        t = Time.zone.parse("#{t.year}-#{t.month}-#{t.day} #{t.hour}:00:00")
        # t = t - t.sec - (60 * (t.min % 60)) # floor to hour
      when :day
        t = Time.zone.parse("#{t.year}-#{t.month}-#{t.day}")
      when :month
        t = Time.zone.parse("#{t.year}-#{t.month}-01")
      when :year
        t = Time.zone.parse("#{t.year}-01-01")
      end
      t
    end


    def read_start_time(start_time)
      start_time = Time.zone.now if start_time.nil?
      if start_time.is_a?(String)
        start_time.gsub!("/", "-")
        begin
          start_time = Time.zone.parse(start_time)
        rescue Exception => e
          case start_time.size
          when 2
            start_time = Time.zone.parse("20#{start_time}-01-01")
          when 4
            start_time = Time.zone.parse("#{start_time}-01-01")
          when 7
            start_time = Time.zone.parse("#{start_time}-01")
          else
            raise ArgumentError, "Start time not valid"
          end
        end
      end
      start_time
    end


    def sum_all_elements
      @v.inject(0.0){|total, n| total + (n||0.0) }
    end

    def count_all_elements
      @v.size
    end
    
    def validate_unit(unit)
      raise ArgumentError, "Time unit is not valid" if !@@valid_units.include? unit
    end

    def get_current_time_zone
      begin
        Time.now.strftime("%Z")        
      rescue Exception => e
        "Rome"
      end
    end

  end

end