**Tuples**

*Bank Commands:*  
Register - ["bank", "request", "register", account_name]  
Buy      - ["bank", "request", "buy", account_name, stock_name, quantity]  
Sell     - ["bank", "request", "sell", account_name, stock_name, quantity]  
Balance  - ["bank", "request", "balance", "account_name"]  
Print Balances - ["bank", "request", "print_balances"]

*Bank Responses:*  
Confirmation  - ["bank", "response", "confirmation", account_name, bank_command, return_value, tuple]  
Failure       - ["bank", "response", "failure", account_name, bank_command, return_value, tuple]  
Game Over	  - ["game_over"]
