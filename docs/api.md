# The response structure
The response structure is
```json
{
    "code": 0,
    "data": "",
    "msg": ""
}
```
The response is ok when the code is  200, otherwise it is wrong, you can handle the error code using the [Error code table]


# API list
## OAuth2 get access token by code
/api/v1/oauth2/access_token?app_id=${}&code=${}&app_key={} GET
```json
{
    "access_token": "",
    "refresh_token": "",
    "expires_in": 1800
}
```

## OAuth2 refresh token
/api/v1/oauth2/access_token?app_id=${}&refresh_token=${} GET
```json
{
    "access_token": "",
    "refresh_token": "",
    "expires_in": 1800
}
```

## Send transaction
/api/v1/oauth2/send_tx POST

Request params with access token on http header named Access-Token

```json
{
    "chainid": "",
    "domain": "",
    "function": "",
    "args": []
}
```

response when function is view or pure
```json 
{
    "eth_address": "",
    "contract_address": "",
    "nonce": 0,
    "chainid": "",
    "domain": "",
    "function": "",
    "args": [],
    "result": "",
    "data": "ok",
    "act": "SUCCESS"
}
```

response when function is others
```json 
{
    "eth_address": "",
    "contract_address": "",
    "nonce": 0,
    "chainid": "",
    "domain": "",
    "function": "",
    "args": [],
    "gas": "0",
    "gas_price": "0 wei",
    "fee": "0 MET",
    "data": "ok",
    "act": "SIGN"
}
```

## Send transaction by owner
/api/v1/oauth2/send_tx_owner POST

http header

| Param       |
| --------   | 
| appid      | 
| appkey      | 
| username      | 

Request params 
```json
{
    "chainid": "",
    "domain": "",
    "function": "",
    "args": []
}
```

response when function is view or pure
```json 
{
    "tx": "0x00",
    "chainid": "",
    "domain": "",
    "result": "",
    "act": "CREATE"
}
```


## Query transaction
/api/v1/oauth2/query_tx POST

Request params with access token on http header named Access-Token
```json
{
    "chainid": "",
    "tx": ""
}
```

response 
```json 
{
    "tx": "",
    "status": "IN_PROGRESS FAILED SUCCEED",
    "chainid": "",
    "domain": "",
    "data": [],
    "act": "SUCCESS"
}
```


# Error code table

| Code       | Meaning   |
| --------   | -----:  |
| 20001      | App id is empty | 
| 20002      | App key is empty   |  
| 20003      | App not existed    |  
| 20004      | Code is empty    |  
| 20005      | Code not existed    |  
| 20006      | Refresh token is empty    |  
| 20007      | Refresh token not existed    |  
| 20008      | Access token is empty    |  
| 20009      | Access token not existed    |  
| 20010      | User not existed    |  
| 20011      | ChainId is empty | 
| 20012      | Domain is empty   |  
| 20013      | Domain not existed    |  
| 20014      | Function is empty   |  
| 20015      | Args not valid    |  
| 20016      | Function not existed    |  
| 20017      | Contract execute error   |  
| 20018      | User balance not enough    |  
| 20019      | Connect to chain rpc error    |  
| 20020      | Tx is empty   |  
| 20021      | Transaction does not existed    |  
| 20022      | Domain abi is empty    |  
👋
