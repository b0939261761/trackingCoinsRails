Exchange.create(name: 'binance') unless Exchange.find_by(name: 'binance')
Exchange.create(name: 'yobit') unless Exchange.find_by(name: 'yobit')
