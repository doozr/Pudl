pipeline "code.stats" do

  task :setup do
    context do
      set :script do
        logger.info "Reading sample.rb"
        File.readlines("sample.rb").map(&:chomp)
      end
    end
  end

  task :basic_stats do
    after :setup

    context do
      set :line_lengths do
        Array.new(get(:script).length)
      end
    end
  end

  eachtask :num_lines do
    after :basic_stats
    source :script

    task do |line, index|
      context do
        set :line_lengths do |ll|
          ll[index] = line.length
          ll
        end

        set :blank_lines do |bl|
          bl ||= 0
          if line.empty?
            bl + 1
          else
            bl
          end
        end
      end
    end
  end

  task :display do
    after :num_lines

    ruby do
      code do
        line_lengths = get :line_lengths
        num_lines = line_lengths.length
        logger.info "There are #{num_lines} lines, of which #{get :blank_lines} are blank"
        logger.info "The average line length is #{line_lengths.reduce(:+) / num_lines}"
      end
    end
  end

end
