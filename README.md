stiker
======


Tuples

Bank Commands:
Register - ["bank", "register", account_name]
Buy      - ["bank", "buy", account_name, stock_name, quantity]
Sell     - ["bank", "sell", account_name, stock_name, quantity]


Bank Responses:
Confirmation  - ["bank", "confirmation", account_name, bank_command, return_value, tuple]
Failure       - ["bank", "failure", account_name, bank_command, return_value, tuple]