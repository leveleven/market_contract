// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
}

contract Market{
    event USDTReceive(
        address indexed buyer,
        uint core,
        uint day,
        uint cost
    );

    modifier OnlyController() {
        require(isController[msg.sender], "Only the controller can use");
        _;
    }

    modifier OnlyOwner() {
        require(isOwner[msg.sender], "Only the owner can use");
        _;
    }

    bool private sendToOwner = false;

    address private owner;
    address private controller;
    
    mapping(address => bool) private isOwner;
    mapping(address => bool) private isController;

    IERC20 private usdt;

    constructor(address _owner, address _controller, address _usdt) {
        owner = _owner;
        isOwner[_owner] = true;

        controller = _controller;
        isController[_controller] = true;

        usdt = IERC20(_usdt);
    }

    function usdtApprove(uint _core, uint _days) internal returns (uint) {
        // 计算金额
        uint cost;
        if (_days == 30) {
            cost = _core * _days * 6 * 15 * 10 ** 3;
        } else if (_days == 60) {
            cost = _core * _days * 6 * 13 * 10 ** 3;
        } else if (_days == 90) {
            cost = _core * _days * 6 * 125 * 10 ** 2;
        } else {
            require(false, "Invalid days, must be 30, 60 or 90");
        }
        // 授权金额
        bool success = usdt.approve(msg.sender, cost);
        require(success, "USDT approve failed");
        return cost;
    }

    // 接收并转发usdt到合约所有者
    function usdtReceive(uint _core, uint _days) external {
        uint cost = usdtApprove(_core, _days);
        // 发起转账
        bool transfer = usdt.transferFrom(msg.sender, address(this), cost);
        require(transfer, "USDT transfer failed");

        // 将代币发送到合约所有者的地址
        if (sendToOwner) {
            usdt.transfer(owner, cost);
        }

        emit USDTReceive(msg.sender, _core, _days, cost);
    }

    function getOwner() external OnlyOwner view returns (address) {
        return owner;
    }

    // 合约拥有者设置 (调用出错)
    function setOwner(address _newOwner) external OnlyController {
        require((_newOwner != owner), "Please set a new owner.");
        isOwner[owner] = false;
        owner = _newOwner;
        isOwner[_newOwner] = true;
    }

    // 设置控制合约
    function setController(address _newController) external OnlyController {
        require((_newController != controller), "Please set a new controller.");
        isController[controller] = false;
        controller = _newController;
        isController[_newController] = true;
    }

    function getSendSwitch() external OnlyOwner view returns (bool) {
        return sendToOwner;
    }

    // 自动发送到owner钱包开关
    function sendSwitch() external OnlyOwner {
        sendToOwner = !sendToOwner;
    }

    // 手动提款
    function usdtWithdraw() external OnlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        usdt.transfer(owner, balance);
    }
}