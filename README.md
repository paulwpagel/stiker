stiker
======


Tuples
Bank Commands
Register - ["bank", "register", <account>]
Buy      - ["bank", "buy", <account>, <stock_name>, <quantity>]
Sell     - ["bank", "sell", <account>, <stock_name>, <quantity>]


Bank Responses
Confirmation  - ["bank", "confirmation", <account>, tuple]
Failure       - ["bank", "failure", <account>, tuple]
