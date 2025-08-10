// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CCNCarnival2025 {
    
    enum OperatingDays { Friday, FriSat, FriSatSun }

    struct Stall {
        address payable owner;
        OperatingDays duration;
        uint256 balance;
        bool registered;
        bool withdrawn;
    }

    mapping(uint => Stall) public stalls;
    mapping(uint => mapping(address => uint256)) public payments;

    mapping(uint => address[]) private stallPayers;
    mapping(uint => mapping(address => bool)) private hasPaidBefore;

    mapping(uint => mapping(address => bool)) public refundRequested;

    uint public stallCount;

    event StallRegistered(uint stallId, address owner, OperatingDays duration);
    event PaymentMade(uint stallId, address payer, uint amount);
    event RefundIssued(uint stallId, address user, uint amount);
    event FundsWithdrawn(uint stallId, address owner, uint amount);
    event RefundDenied(uint stallId, address buyer);

    modifier stallExists(uint _stallId) {
        require(_stallId > 0 && _stallId <= stallCount, "Stall does not exist");
        _;
    }

    function registerStall(OperatingDays _duration) external {
        stallCount++;
        stalls[stallCount] = Stall(payable(msg.sender), _duration, 0, true, false);
        emit StallRegistered(stallCount, msg.sender, _duration);
    }

    function makePayment(uint _stallId) external payable stallExists(_stallId) {
        Stall storage s = stalls[_stallId];
        require(s.registered, "Stall not found");
        require(!s.withdrawn, "Stall funds withdrawn, no more payments");
        require(msg.value > 0, "Must send ETH");

        s.balance += msg.value;
        payments[_stallId][msg.sender] += msg.value;

        if (!hasPaidBefore[_stallId][msg.sender]) {
            stallPayers[_stallId].push(msg.sender);
            hasPaidBefore[_stallId][msg.sender] = true;
        }

        emit PaymentMade(_stallId, msg.sender, msg.value);
    }

    function issueRefund(uint _stallId, address _user) external stallExists(_stallId) {
        Stall storage s = stalls[_stallId];
        require(msg.sender == s.owner, "Not stall owner");

        uint256 amount = payments[_stallId][_user];
        require(amount > 0, "No payment to refund");
        require(amount <= s.balance, "Refund exceeds stall balance");

        s.balance -= amount;
        payments[_stallId][_user] = 0;

        (bool success, ) = payable(_user).call{value: amount}("");
        require(success, "Refund transfer failed");

        emit RefundIssued(_stallId, _user, amount);
    }

    function withdrawFunds(uint _stallId) external stallExists(_stallId) {
        Stall storage s = stalls[_stallId];
        require(msg.sender == s.owner, "Not stall owner");
        require(!s.withdrawn, "Already withdrawn");
        require(block.timestamp >= getWithdrawalTime(s.duration), "Too early"); //remove for testing

        uint amount = s.balance;
        s.withdrawn = true;
        s.balance = 0;

        (bool success, ) = s.owner.call{value: amount}("");
        require(success, "Withdrawal transfer failed");

        emit FundsWithdrawn(_stallId, s.owner, amount);
    }

    function getWithdrawalTime(OperatingDays duration) public pure returns (uint) {
        if (duration == OperatingDays.Friday) return 1 days;
        if (duration == OperatingDays.FriSat) return 2 days;
        return 3 days;
    }

    function getPayers(uint _stallId) external view stallExists(_stallId) returns (address[] memory) {
        return stallPayers[_stallId];
    }

    function requestRefund(uint _stallId) external stallExists(_stallId) {
        require(payments[_stallId][msg.sender] > 0, "No payment made");
        require(!refundRequested[_stallId][msg.sender], "Refund already requested");
        
        refundRequested[_stallId][msg.sender] = true;
    }

    function approveRefund(uint _stallId, address _buyer) external stallExists(_stallId) {
        Stall storage s = stalls[_stallId];
        require(msg.sender == s.owner, "Not stall owner");
        require(refundRequested[_stallId][_buyer], "No refund requested");

        uint256 amount = payments[_stallId][_buyer];
        require(amount > 0, "No payment to refund");
        require(amount <= s.balance, "Refund exceeds stall balance");

        refundRequested[_stallId][_buyer] = false;

        s.balance -= amount;
        payments[_stallId][_buyer] = 0;

        (bool success, ) = payable(_buyer).call{value: amount}("");
        require(success, "Refund transfer failed");

        emit RefundIssued(_stallId, _buyer, amount);
    }

    function denyRefund(uint _stallId, address _buyer) 
        external 
        stallExists(_stallId) 
    {
        Stall storage s = stalls[_stallId];
        require(msg.sender == s.owner, "Not stall owner");
        require(refundRequested[_stallId][_buyer], "No refund requested");

        refundRequested[_stallId][_buyer] = false;

        emit RefundDenied(_stallId, _buyer);
    }
}