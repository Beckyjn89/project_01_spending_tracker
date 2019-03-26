require_relative('../db/sql_runner.rb')

class Transaction

  attr_reader :id
  attr_accessor :name, :tag_id, :merchant_id, :account_id, :spend, :date

  def initialize(options)
    @id = options['id'].to_i if options['id']
    @tag_id = options['tag_id'].to_i
    @merchant_id = options['merchant_id'].to_i
    @account_id = options['account_id'].to_i
    @spend = options['spend'].to_f
    @date = options['date']
  end

  def save()
    sql = "INSERT INTO transactions (tag_id, merchant_id, account_id, spend, date) VALUES ($1, $2, $3, $4, $5) RETURNING id"
    values = [@tag_id, @merchant_id, @account_id, @spend, @date]
    result = SqlRunner.run(sql, values)
    id = result.first['id']
    @id = id.to_i
  end

  def self.find(id)
    sql = "SELECT * FROM transactions WHERE id = $1"
    values = [id]
    result = SqlRunner.run(sql, values)
    transaction_data = result.first
    transaction = Transaction.new(transaction_data)
    return transaction
  end

  def update()
    sql = "UPDATE transactions SET (tag_id, merchant_id, account_id, spend) = ($1, $2, $3, $4) WHERE id = $5"
    values = [@tag_id, @merchant_id, @account_id, @spend, @id]
    SqlRunner.run(sql, values)
  end

  def delete()
    sql = "DELETE FROM transactions
          WHERE id = $1"
    values = [@id]
    SqlRunner.run(sql, values)
  end

  def self.all()
    sql = "SELECT * FROM transactions ORDER BY date DESC;"
    transaction_data = SqlRunner.run(sql)
    return Transaction.map_items(transaction_data)
  end

  def self.decide_which_filter(tag_id, merchant_id)
    case
    when tag_id == "all" && merchant_id == "all"
      return self.all()
    when tag_id != "all" && merchant_id != "all"
      return self.filter_by_tag_and_merchant(tag_id, merchant_id)
    when tag_id == "all" && merchant_id != "all"
      return self.filter_by_merchant(merchant_id)
    when tag_id != "all" && merchant_id == "all"
      return self.filter_by_tag(tag_id)
  end
end

  def self.filter_by_tag(tag_id)
    sql = "SELECT * FROM transactions
    WHERE tag_id = $1"
    values = [tag_id]
    transaction_data = SqlRunner.run(sql, values)
    return Transaction.map_items(transaction_data)
  end

  def self.filter_by_merchant(merchant_id)
    sql = "SELECT * FROM transactions
    WHERE merchant_id = $1"
    values = [merchant_id]
    transaction_data = SqlRunner.run(sql, values)
    return Transaction.map_items(transaction_data)
  end

  def self.filter_by_tag_and_merchant(tag_id, merchant_id)
    sql = "SELECT * FROM transactions
    WHERE tag_id = $1
   AND merchant_id = $2"
    values = [tag_id, merchant_id]
    transaction_data = SqlRunner.run(sql, values)
    return Transaction.map_items(transaction_data)
  end

  def self.map_items(transaction_data)
    return transaction_data.map { |transaction| Transaction.new(transaction) }
  end

  def self.delete_all
    sql = "DELETE FROM transactions"
    SqlRunner.run(sql)
  end

  def show_tag_name
    sql = "SELECT tags.name AS tag_name FROM tags
    WHERE tags.id = $1"
    values = [@tag_id]
    tag_name = SqlRunner.run(sql, values)
    return tag_name.first['tag_name']
  end

  def show_merchant_name
    sql = "SELECT merchants.name AS merchant_name FROM merchants
    WHERE merchants.id = $1"
    values = [@merchant_id]
    merchant_name = SqlRunner.run(sql, values)
    return merchant_name.first['merchant_name']
  end

  def self.total_spend
    sql = "SELECT SUM(spend) FROM transactions"
    result = SqlRunner.run(sql)
    return result.first['sum'].to_i
  end

  def date_display
    date = Date.parse(@date)
    return "#{date.mday} #{Date::ABBR_MONTHNAMES[date.mon]} #{date.year}"
  end

  def price_display
    return "£%.2f" % @spend
  end

end
