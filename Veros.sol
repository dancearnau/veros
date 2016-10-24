pragma solidity ^0.4.2;
contract Veros {

    event Created(bytes32 indexed identifier);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    struct walletStruct {
        uint balance;
        uint blockedUntil;
        bool permanentBlocked;
    }

	mapping (address => walletStruct) balances;
	mapping (uint => address) accountIndex;
    uint _accountCount = 0;

    address _genesisWallet;
    function getGenesisWalletAddress() constant returns (address walletAddress) {
        return _genesisWallet;
    }

	address _mainWallet;
	function getMainWalletAddress() constant returns (address walletAddress) {
        return _mainWallet;
    }


	uint blockSize = 100000000;
	uint numberOfBlocks = 100;
	
	/* ----------------------------------------------------------------------------------------------------------------------------------------------------------------
     * Testing
     */
     
    uint _offsetTime = 0;
    function setOffsetTime(uint offsetTime) {
        _offsetTime = offsetTime;
    }
	
    /* ----------------------------------------------------------------------------------------------------------------------------------------------------------------
     * Constructor
     */

	function Veros(bytes32 identifier, address genesisWallet, address mainWallet) {
	    Created(identifier);

	    _genesisWallet = genesisWallet;
	    _mainWallet = mainWallet;

	    walletStruct memory genesisWalletData;
	    genesisWalletData.balance = (numberOfBlocks-1) * blockSize;
	    genesisWalletData.permanentBlocked = true;
		balances[_genesisWallet] = genesisWalletData;

		walletStruct memory mainWalletData;
        mainWalletData.balance = blockSize;
        mainWalletData.permanentBlocked = true;
		balances[_mainWallet] = mainWalletData;

		registerInternalAddress(_genesisWallet);
		registerInternalAddress(_mainWallet);
		
		saveTransaction(_genesisWallet, _mainWallet, blockSize);
	}
	
	function registerAddress() {
	    accountIndex[_accountCount] = msg.sender;
	    _accountCount++;
	}

    /*
     * Register a new address
     */
	function registerInternalAddress(address walletAddress) internal {
	    accountIndex[_accountCount] = walletAddress;
	    _accountCount++;
	}

    /*
     * Get VERO balance
     */
	function getBalance(address walletAddress) constant returns(uint) {
	    walletStruct walletData = balances[walletAddress];
		return walletData.balance;
	}

    /* ----------------------------------------------------------------------------------------------------------------------------------------------------------------
     * Address to IPv4
     */

     mapping (address => uint32) ips;

     function setIP(uint32 ip) {
         ips[msg.sender] = ip;
     }

     function deleteIP() {
         delete ips[msg.sender];
     }

     function getIP(address addr) returns (uint32) {
         return ips[addr];
     }


     /* ----------------------------------------------------------------------------------------------------------------------------------------------------------------
      * Explorer
      */

    function getTotalSupply() constant returns (uint totalSupply) {
        for (uint i=0;i<_accountCount;i++) {
            address accountAddress = accountIndex[i];
            walletStruct walletData = balances[accountAddress];
            totalSupply += walletData.balance;
        }
        return totalSupply;
    }

    function getAvailableSupply() constant returns (uint availableSupply) {
        uint totalSupply = 0;
        for (uint i=0;i<_accountCount;i++) {
            address accountAddress = accountIndex[i];
            walletStruct walletData = balances[accountAddress];
            if (walletData.permanentBlocked != true) {
                totalSupply += walletData.balance;
            }
        }
        return availableSupply;
    }
    
    /* ----------------------------------------------------------------------------------------------------------------------------------------------------------------
     * Transactions
     */
     
     function sendVeros(address recipient, uint amount) returns(bool sufficient) {
        walletStruct senderWalletData = balances[msg.sender];
        walletStruct recipientWalletData = balances[recipient];

        if (senderWalletData.balance < amount) {
            return false;
         }

        senderWalletData.balance -= amount;
        recipientWalletData.balance += amount;

        balances[msg.sender] = senderWalletData;
        balances[recipient] = recipientWalletData;

        saveTransaction(msg.sender, recipient, amount);

        return true;
    }
     
    struct transactionStruct {
        uint datetime;
        uint blockNumber;
        uint amount;
        address receiver;
        address sender;
    }

    mapping(uint256 => transactionStruct) _transactionList;
    uint _transactionCount = 0;

	function saveTransaction(address sender, address recipient, uint amount) internal {
        transactionStruct memory transactionItem;
        transactionItem.amount = amount;
        transactionItem.receiver = recipient;
        transactionItem.sender = sender;
        transactionItem.blockNumber = block.number;
        transactionItem.datetime = block.timestamp;

        _transactionList[_transactionCount] = transactionItem;
        _transactionCount++;
        Transfer(sender, recipient, amount);
	}

	function getTransactionCount() constant returns (uint transactionCount) {
	    return _transactionCount;
	}

    function getTransactionAmountWithIndex(uint transactionIndex) constant returns (uint amount) {
        transactionStruct transactionItem = _transactionList[transactionIndex];
        return transactionItem.amount;
    }

    function getTransactionDateWithIndex(uint transactionIndex) constant returns (uint datetime) {
        transactionStruct transactionItem = _transactionList[transactionIndex];
        return transactionItem.datetime;
    }

    function getTransactionSenderWithIndex(uint transactionIndex) constant returns (address sender) {
        transactionStruct transactionItem = _transactionList[transactionIndex];
        return transactionItem.sender;
    }

    function getTransactionRecipientWithIndex(uint transactionIndex) constant returns (address recipient) {
        transactionStruct transactionItem = _transactionList[transactionIndex];
        return transactionItem.receiver;
    }

    function getTransactionBlockNumberWithIndex(uint transactionIndex) constant returns (uint blockNumber) {
        transactionStruct transactionItem = _transactionList[transactionIndex];
        return transactionItem.blockNumber;
    }
    
    /* ----------------------------------------------------------------------------------------------------------------------------------------------------------------
     * Schedule Payments
     */    
     
    uint _scheduledPaymentIndex = 0;

    struct scheduledPaymentStruct {
        uint date;
        uint amount;
        address receiver;
    }

    mapping(uint256 => scheduledPaymentStruct) _scheduledPayments;
    uint[] _scheduledPaymentIndexes;

    function setSchedulePayment(address receiver, uint amount, uint date) returns (uint scheduledPaymentIndex) {
        
        if (msg.sender != _mainWallet) {
            return 0;
        }

        scheduledPaymentStruct memory sPaymentStruct;
        sPaymentStruct.amount = amount;
        sPaymentStruct.receiver = receiver;
        sPaymentStruct.date = date;

        _scheduledPayments[_scheduledPaymentIndex] = sPaymentStruct;
        _scheduledPaymentIndexes.push(_scheduledPaymentIndex);
        _scheduledPaymentIndex++;

        return _scheduledPaymentIndex;
    }

    function getSchedulePaymentAddress(uint scheduledPaymentIndex) constant returns (address scheduledPaymentAddress) {
        scheduledPaymentStruct sPaymentStruct = _scheduledPayments[scheduledPaymentIndex];
        return sPaymentStruct.receiver;
    }

    function getSchedulePaymentAmount(uint scheduledPaymentIndex) constant returns (uint scheduledPaymentAmount) {
        scheduledPaymentStruct sPaymentStruct = _scheduledPayments[scheduledPaymentIndex];
        return sPaymentStruct.amount;
    }

    function getSchedulePaymentDate(uint scheduledPaymentIndex) constant returns (uint scheduledPaymentDate) {
        scheduledPaymentStruct sPaymentStruct = _scheduledPayments[scheduledPaymentIndex];
        return sPaymentStruct.date;
    }

    function getScheduledPaymentIndex() constant returns (uint scheduledPaymentIndex) {
        return _scheduledPaymentIndex;
    }

    function getPaymentAtIndex(uint index) constant returns (uint paymentIndex) {
        return _scheduledPaymentIndexes[index];
    }
    
    function getScheduledPaymentsActiveCount() constant returns (uint scheduledPaymentsCount) {
        uint paymentsRunCount = 0;
        for (uint i = 0; i<_scheduledPaymentIndex;i++) {
            scheduledPaymentStruct sPaymentStruct = _scheduledPayments[i];
            uint currentTime = getCurrentTime();
            if (sPaymentStruct.date<currentTime && sPaymentStruct.date > 0) {
                paymentsRunCount++;
            }
        }
        return paymentsRunCount;
    }
    
    function getCurrentTime() constant returns (uint currentTime) {
        currentTime = block.timestamp;
        currentTime += _offsetTime;
        return currentTime;
    }

    function runScheduledPayments()  {
        uint paymentsRunCount = 0;
        for (uint i = 0; i<_scheduledPaymentIndex;i++) {
            scheduledPaymentStruct sPaymentStruct = _scheduledPayments[i];
            uint currentTime = block.timestamp;
            if (sPaymentStruct.date<currentTime && sPaymentStruct.date > 0) {
                address receiver = sPaymentStruct.receiver;
                uint amount = sPaymentStruct.amount;

                walletStruct mainWalletData = balances[_mainWallet];
                mainWalletData.balance -= amount;
                balances[_mainWallet] = mainWalletData;
                
                walletStruct receiverWalletData = balances[receiver];
                receiverWalletData.balance += amount;
                balances[receiver] = receiverWalletData;
                
                saveTransaction(_mainWallet, receiver, amount);
                paymentsRunCount++;

                delete _scheduledPayments[i];
            }
        }
    }     
}
