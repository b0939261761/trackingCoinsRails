Exchange.create(name: 'Binance') unless Exchange.find_by(name: 'Binance')
Exchange.create(name: 'YObit') unless Exchange.find_by(name: 'YObit')
Exchange.create(name: 'HitBTC') unless Exchange.find_by(name: 'HitBTC')
