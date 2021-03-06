require_relative('../db/sql_runner.rb')
require_relative('./transaction.rb')

class Merchant

  attr_reader :id
  attr_accessor :name

  def initialize(options)
    @id = options['id'].to_i if options['id']
    @name = options['name']
  end

  def save()
    sql = "INSERT INTO merchants (name) VALUES ($1) RETURNING id"
    values = [@name]
    result = SqlRunner.run(sql, values)
    id = result.first['id']
    @id = id.to_i
  end

  def self.find(id)
    sql = "SELECT * FROM merchants WHERE id = $1"
    values = [id]
    result = SqlRunner.run(sql, values)
    merchant_data = result.first
    merchant = Merchant.new(merchant_data)
    return merchant
  end

  def update()
    sql = "UPDATE merchants SET name = $1 WHERE id = $2"
    values = [@name, @id]
    SqlRunner.run(sql, values)
  end

  def delete()
    sql = "DELETE FROM merchants
          WHERE id = $1"
    values = [@id]
    SqlRunner.run(sql, values)
  end

  def self.all()
    sql = "SELECT * FROM merchants ORDER BY name ASC"
    merchant_data = SqlRunner.run(sql)
    return Merchant.map_items(merchant_data)
  end

  def self.all_by_date()
    sql = "SELECT merchants.* FROM merchants
    INNER JOIN transactions
    ON transactions.merchant_id = merchants.id
    ORDER BY transactions.date DESC"
    merchant_data = SqlRunner.run(sql)
    return Merchant.map_items(merchant_data)
  end

  def self.map_items(merchant_data)
    return merchant_data.map { |merchant| Merchant.new(merchant) }
  end

  def self.delete_all
  sql = "DELETE FROM merchants"
  SqlRunner.run(sql)
  end

  def decide_filter(month, year)
    if (month == "" && year == "") || (month == nil && year == nil)
      return total_spend()
    else
      return total_spend_mon(month.to_i, year.to_i)
    end
  end

  def total_spend()
    sql = "SELECT SUM(transactions.spend) FROM transactions
    WHERE transactions.merchant_id = $1"
    values = [@id]
    result = SqlRunner.run(sql, values)
    return result.first['sum'].to_f
  end

  def total_spend_mon(month, year)
    sql = "SELECT SUM(spend) AS total_spend FROM transactions
    WHERE merchant_id = $1 AND
    EXTRACT(month FROM date) = $2 AND EXTRACT(year FROM date) = $3"
    values = [@id, month, year]
    result = SqlRunner.run(sql, values)
    return spent = result.first['total_spend'].to_f
  end

  def all_transactions()
    sql = "SELECT * from transactions
    WHERE merchant_id = $1
    ORDER BY date DESC"
    # sql = "SELECT transactions.* from transactions
    # INNER JOIN merchants
    # ON transactions.merchant_id = merchants.id
    # WHERE transactions.merchant_id = $1"
    values = [@id]
    transaction_data = SqlRunner.run(sql, values)
    transaction = Transaction.map_items(transaction_data)
  end

  def avg_spend()
    sql = "SELECT ROUND(AVG(transactions.spend), 2) FROM  merchants
    INNER JOIN transactions
    ON transactions.merchant_id = $1"
    values = [@id]
    result = SqlRunner.run(sql, values)
    return result.first['round'].to_f
  end

end
