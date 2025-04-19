class CleanupProductNames < ActiveRecord::Migration[8.0]
  def up
    # Get existing products
    products = execute("SELECT id, product_name, product_type FROM products").to_a

    # Process each product and update names
    products.each do |product|
      id = product["id"]
      name = product["product_name"]
      type = product["product_type"]

      new_name = name

      # Remove redundant prefixes based on type
      if type == "adhesion" && name.start_with?("Adhésion ")
        new_name = name.gsub(/^Adhésion\s+/, '')
      elsif type == "cotisation" && name.start_with?("Cotisation ")
        new_name = name.gsub(/^Cotisation\s+/, '')
      end

      # Update the product if name changed
      if new_name != name
        execute("UPDATE products SET product_name = '#{new_name}' WHERE id = #{id}")
      end
    end
  end

  def down
    # Get existing products
    products = execute("SELECT id, product_name, product_type FROM products").to_a

    # Process each product and restore original names
    products.each do |product|
      id = product["id"]
      name = product["product_name"]
      type = product["product_type"]

      original_name = name

      # Add type prefix back
      if type == "adhesion" && !name.start_with?("Adhésion ")
        original_name = "Adhésion #{name}"
      elsif type == "cotisation" && !name.start_with?("Cotisation ")
        original_name = "Cotisation #{name}"
      end

      # Update the product if name changed
      if original_name != name
        execute("UPDATE products SET product_name = '#{original_name}' WHERE id = #{id}")
      end
    end
  end
end
