class Job

  def Job.submit(*args, &block)
    job = case args.size
          when 0
            raise ArgumentError
          else
            object = object_for(args.shift)
            message = (args.shift || :perform).to_s
            Worker.perform_async(object, message, args)
          end
  end

  def Job.object_for(value)
    value.to_s
  end
end