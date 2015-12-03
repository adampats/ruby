# Just some useful tricks

# Hash monkey patches

class Hash

  # filter for certain keys w/ values
  def filter(*args)
    return nil if args.nil?
    if args.size == 1
      args[0] = args[0].to_s if args[0].is_a?(Symbol)
      self.select {|key| key.to_s.match(args.first) }
    else
      self.select {|key| args.include?(key)}
    end
  end

  # convert string keys to symbols - like Rails #symbolize_keys
  def symbolize
    return nil if self.nil?
    self.keys.each do |key|
      self[(key.to_sym rescue key) || key] = self.delete(key)
    end
  end

end
