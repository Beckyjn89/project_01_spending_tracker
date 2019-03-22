require_relative('../db/sql_runner.rb')

class Transaction

  attr_reader :id
  attr_accessor :name, :tag_id, :merchant_id, :account_id, :spend

  def initialize(options)
    @id = options['id'].to_i if options['id']
    @tag_id = options['tag_id'].to_i
    @merchant_id = options['merchant_id'].to_i
    @account_id = options['account_id'].to_i
    @spend = options['spend'].to_i
  end

  def save()
    sql = "INSERT INTO transactions (tag_id, merchant_id, account_id, spend) VALUES ($1, $2, $3, $4) RETURNING id"
    values = [@tag_id, @merchant_id, @account_id, @spend]
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
    sql = "SELECT * FROM transactions"
    transaction_data = SqlRunner.run(sql)
    return Transaction.map_items(transaction_data)
  end

  def self.map_items(transaction_data)
    return transaction_data.map { |transaction| Transaction.new(transaction) }
  end

  def self.delete_all
  sql = "DELETE FROM transactions"
  SqlRunner.run(sql)
  end

end
