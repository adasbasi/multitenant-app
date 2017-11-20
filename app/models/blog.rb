class Blog < ApplicationRecord
    has_many :post, :dependent => :destroy
end
