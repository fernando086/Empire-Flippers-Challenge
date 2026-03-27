class Listing < ApplicationRecord
  # Valida en memoria que 'listing_number' esté presente y sea completamente único antes de guardar
  validates :listing_number, presence: true, uniqueness: true
end
