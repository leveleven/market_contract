# Market合约
> 为了自动计算商品并收款设计合约

## 合约
为使用多签, 将合约分为Market和Controller, Market为对外, Controller控制Market敏感操作

### Market
#### 创建
- _owner 设置合约拥有者 (钱包地址)
- _controller 设置合约控制者 (合约地址)
- _usdt 设置usdt合约地址, 本合约目前只支持erc20上面的usdt进行交易 (合约地址)
#### 事件
```
event USDTReceive(address indexed buyer, uint core, uint day, uint cost); # 订单付款事件
```
#### 权限
```
modifier OnlyController() # 只允许控制合约进行调用
modifier OnlyOwner()      # 只允许合约拥有者进行调用
```
#### 方法
```
function usdtReceive(uint _core, uint _days) external                  # 订单付款方法
function setOwner(address _newOwner) external OnlyController           # 设置合约拥有者(钱包地址)
function setController(address _newController) external OnlyController # 设置合约控制者(合约地址)
function getSendSwitch() external OnlyOwner view returns (bool)        # 获取自动提款开关
function sendSwitch() external OnlyOwner                               # 付款完成后自动将合约usdt提取到合约owner开关
function usdtWithdraw() external OnlyOwner                             # 手动将合约中的usdt提取到合约owner
```