class Resource < ApplicationRecord
    enum resource_type: { discount: 0, govt_program: 1, local_support: 2, tax_prep: 3, product: 4 }
end
