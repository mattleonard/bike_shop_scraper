class Worker
  include Sidekiq::Worker
  def perform(class_name, function_name, args)
    begin
      klass = class_name.constantize
      klass.send(function_name, *args)
    rescue => e
      raise e
    end
  end
end
