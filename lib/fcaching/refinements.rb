module Refinements
  refine Kernel do
    alias_method :then, :yield_self
  end
end
