module EnergyMarket

  include MyUtil

  class ValuesArray < Array; end

  class Vector
    attr_reader :start_time, :v, :step
    # @@valid_units = %w( hour day month year )
    @@valid_units = [:hour, :day, :month, :year]

    def initialize(start_time=Time.zone.now, zone="Rome")
      Time.zone = zone
      start_time = read_start_time(start_time)
      @start_time = floor_start_time(start_time)
      @v = ValuesArray.new
    end

    def clone
      Vector.new(@start_time).data(@v.clone)
    end


    def data(data, unit=:hour)
      unit = unit.to_sym
      data = [data] unless data.is_a? Array
      @v = ValuesArray.new
      validate_unit unit
      start_time = @start_time.clone

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
        when :positive
          @v.inject(0.0){|total, n| total + (n>0.0 ? n : 0.0) }
        when :negative
          @v.inject(0.0){|total, n| total + (n<0.0 ? n : 0.0) }
        when :not_positive
          @v.inject(0.0){|total, n| total + (n<=0.0 ? n : 0.0) }
        when :not_negative
          @v.inject(0.0){|total, n| total + (n>=0.0 ? n : 0.0) }
        when :not_zero
          sum_all_elements
        when :zero
          0.0
        when :all
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
    alias :size :count


    # Return the mean of values
    def mean(options = {})
      c = count(options) # if count is zero a NaN will be returned
      # raise ZeroDivisionError if c.zero?
      sum(options) / c
    end


    def minimum_value
      min=@v.first
      @v.each{|v| min=v if v<min }
      min
    rescue
      # if the first value or all values are nil
      nil
    end

    def maximum_value
      max=@v.first
      @v.each{|v| max=v if v>max }
      max
    rescue
      # if the first value or all values are nil
      nil
    end


    def round!(ndigit=3)
      @v.collect!{|v| v.round(ndigit)}
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
      return nil if @v.empty?
      @start_time + (@v.size-1).hours
      # case @unit
      # when '15minutes'
      #   @start_time + ((@v.size-1)*15).minutes
      # when 'hour'
      #   @start_time + (@v.size-1).hours
      # when 'day'
      #   @start_time + (@v.size-1).days
      # when 'month'
      #   @start_time + (@v.size-1).months
      # when 'year'
      #   @start_time + (@v.size-1).years
      # end
    end

    def aligned_with?(v)
      self.start_time==v.start_time && @v.size==v.size
    end
  
    # intersection
    def align_with(vector_2)
      s1, s2 = @start_time, vector_2.start_time
      return nil if s1==s2 && @v.size==vector_2.size
      e1, e2 = self.end_time, vector_2.end_time

      hs = ((s2-s1)/3600).to_i
      ks = hs>0 ? hs : 0
      he = ((e2-e1)/3600).to_i
      ke = he<0 ? he : 0
      ke -= 1

      @v = @v[ks..ke]
      @start_time = (s1>s2 ? s1 : s2)
    end


    def size
      @v.size
    end

    def to_s
      "Start time: #{@start_time}\nData (size: #{@v.size}):\n#{print_values}"
    end

    def print_values
      a = []
      start_time = @start_time.clone
      @v.each do |v|
        a << "#{start_time.strftime('%Y-%m-%d %H:%M %a')}\t#{v}"
        start_time+=1.hour
      end
      a.join("\n")
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
        t = t - t.sec - (60 * (t.min % 60)) # floor to hour
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
  end


end


