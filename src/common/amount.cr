module Amount
  def parse_amount(platform : Data::UserType, id : Int64 | UInt64, string : String) : BigDecimal?
    if string == "all"
      get_balance(platform, id)
    elsif string == "half"
      BigDecimal.new(get_balance(platform, id) / 2).round(8)
    elsif string == "rand"
      BigDecimal.new(Random.rand(1..6))
    elsif string == "bigrand"
      BigDecimal.new(Random.rand(1..42))
    elsif m = /(?<amount>^[0-9,\.]+)/.match(string)
      begin
        return nil unless string == m["amount"]
        BigDecimal.new(m["amount"]).round(8)
      rescue InvalidBigDecimalException
      end
    end
  end

  private def get_balance(platform, id)
    # TODO get rid of static coin
    Data::Account.read(platform, id.to_i64).balance(:doge)
  end
end