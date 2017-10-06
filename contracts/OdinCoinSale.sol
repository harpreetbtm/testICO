pragma solidity ^0.4.11;


import "./OdinCoinToken.sol";
import "./browser/Pausable.sol";
import "./browser/SafeMath.sol";
import "./browser/ERC20.sol";


/*
 * The Odin Coin Sale contract - Features
 *
 * The funding goal for this ICO is a total of 65000 ether. The ICO will run from 1st December 2017 (00:00:00 GMT+2) to 31st December 2017 (23:59:59 GMT+2) with pre ICO period from 15th November 2017 to 30th November 2017
 *
 * Features
 * 1. Any investor can invest in the ICO upto a cap of 3 ether
 * 2. If the investor is KYC approved, they can send as high an amount as they want
 * 3. If an investor who is not KYC approved sends an ether amount greater than 2 ether, then 2 ethers worth of tokens will be issued to him, and the remaining ether amount will be refunded
 * 3. There is a soft ether cap of 50000 ether. Once the contract recieves 50000 ether, all funds will be forwarded to the ICO owners address
 * 4. If the soft ether cap is not reached at the end of the ICO, investors can connect to the contract and withdraw their funds
 * 5. If the soft ether cap is reached by the end of the ICO period, the ICO period will extend indefinetely until the funding goal is reached
 * 6. The ICO can paused/unpaused and stopped (only incase of an emergency wherein the funds will be transferred to a secure wallet, and later refunded to investors)
 */
contract OdinCoinSale is Pausable, SafeMath {


  uint256 public startDate = 1506962129;
  uint256 public endDate   = 1508543755;  // Friday, October 20, 2017 11:55:55 PM

  OdinCoin token;

  uint256 public purchasedCoins;
  uint256 public ethRaised;
  uint256 public contributors;
  uint256 public price             = 714285710000000;
  uint256 public coinsRemaining    = 100000000;
  uint256 public const             = 10**18;
  uint256 public softEtherCap      = 50000 * const;
  uint256 public KYCCap            = 3 * 1 ether ;

  address public cs;
  address public multiSig;
  address public ACT_Reserve;
  address private SecureWallet;

  struct csAction  {
      bool        requireKYC;
      bool        passedKYC;
      bool        blocked;
  }

  // Public method for permissions of an address
  mapping (address => csAction) public permissions;
  // Public method for deposits of an address
  mapping (address => uint256)  public deposits;

  // Modifier to check KYC verification of an address
  modifier MustBeEnabled(address x) {
      require (!permissions[x].blocked) ;
      require(permissions[x].passedKYC || !permissions[x].requireKYC);
      _;
  }

  function OdinCoinSale(address _cs, address _act, address _multiSig, address _reserve,address _secureWallet) {
    cs          = _cs;
    token       = OdinCoin(_act);
    multiSig    = _multiSig;
    ACT_Reserve = _reserve;
    SecureWallet = _secureWallet;
  }

  // Setting start date. Should only be used incase of exceptional circumstances
  function setStart(uint256 when_) onlyOwner {
      startDate = when_;
  }

  modifier MustBeCs() {
      require (msg.sender == cs) ;
      _;
  }

    /* Approve the account for operation */
    function approve(address user) MustBeCs {
        permissions[user].passedKYC = true;
    }

    function block(address user) MustBeCs {
        permissions[user].blocked = true;
    }

    function unblock(address user) MustBeCs {
         permissions[user].blocked = false;
    }

    function triggerRequireKYC(address user) private {
       permissions[user].requireKYC = true;
    }

    function newCs(address newC) onlyOwner {
        cs = newC;
    }

    function when()  constant returns (uint256) {
        return now;
    }

  // Method to check funding status
  function funding() constant returns (bool) {
    if (paused) return false;  //contract is paused
    if (now < startDate) return false;  // too early
    if (ethRaised < softEtherCap && now > endDate){    // Failed to reach softEtherCap in time
        return false;
    }
    if (coinsRemaining == 0) return false;   // run out of coins
    return true;
  }

  function success() constant returns (bool succeeded) {
    if (coinsRemaining == 0) return true;
    bool complete = (now > endDate) ;
    bool didOK = (ethRaised >= softEtherCap);
    succeeded = (complete && didOK)  ;
    return ;
  }

  function failed() constant returns (bool didNotSucceed) {
    bool complete = (now > endDate  );
    bool didBad = (ethRaised < softEtherCap);
    didNotSucceed = (complete && didBad);
    return;
  }


  function () payable MustBeEnabled(msg.sender) whenNotPaused {
    createTokens(msg.sender,msg.value);
  }

  function linkCoin(address coin) onlyOwner {
    token = OdinCoin(coin);
  }

  function coinAddress() constant returns (address) {
      return address(token);
  }

  // Setting price of token in wei
  function setPricePre(uint256 _price) onlyOwner {
              price = _price;
  }
  function setPricePost(uint256 _price) onlyOwner {
              price = _price;
  }


  event Purchase(address indexed buyer,uint256 value, uint256 tokens);
  event Reduction(string msg, address indexed buyer, uint256 wanted, uint256 allocated);
  event MaxFunds(address sender, uint256 taken, uint256 returned);


 function createTokens(address recipient, uint256 value) private {
    //  Check for active fund raiser
    require (funding()) ;
    // Check for minimum values
    require (value >= 1 finney) ;
    // KYC Refund is issued when an unverified user sends more ether than the KYCCap
    // It will trigger KYC Verification required for the user and send the excess ether back to their address
    uint256 KYCRefund = 0;
    if (((deposits[recipient] + value) > KYCCap) && !permissions[recipient].requireKYC && !permissions[recipient].passedKYC) {
        triggerRequireKYC(recipient);
        KYCRefund = deposits[recipient] + value - KYCCap;
        value -= KYCRefund;
        MaxFunds(recipient,value,KYCRefund);
    }
    // Calculate number of tokens
    uint tokens = safeDiv(value,price);
    uint256 actualTokens = tokens;

    // Refund issued when there are more tokens that needs to be issued that what remains in the crowdsale
    // Value in ether of excess tokens are refunded to the sender
    uint coinExhaustedRefund = 0;
    if (tokens > coinsRemaining) {
        Reduction("Sent excess",recipient,tokens,coinsRemaining);
        actualTokens = coinsRemaining;
        coinExhaustedRefund = safeSub(tokens, coinsRemaining ); // refund amount in tokens
        coinExhaustedRefund = safeMul(coinExhaustedRefund,price);  // refund amount in ETH
        coinsRemaining = 0;
        value = safeSub(value,coinExhaustedRefund);
     } else {
        coinsRemaining  = safeSub(coinsRemaining,  actualTokens);
     }

    ethRaised = safeAdd(ethRaised,value);

    if (deposits[recipient] == 0) contributors++;

    purchasedCoins  = safeAdd(purchasedCoins, actualTokens);

    require (token.transferFrom(ACT_Reserve, recipient,actualTokens)) ;

    Purchase(recipient,value,actualTokens);

    deposits[recipient] = safeAdd(deposits[recipient],value);

    if (coinExhaustedRefund > 0 || KYCRefund > 0) {
        recipient.transfer(coinExhaustedRefund+KYCRefund);
    }

    // If the Ether Raised crosses minimum limits we forward the ether to contract owner
    if (ethRaised >= softEtherCap){
        if (!multiSig.send(this.balance)) {
            log0("cannot forward funds to owner");
        }
    }
  }

  // Manual allocation of tokens
  function allocatedTokens(address grantee, uint256 numTokens) onlyOwner {
    //require (now < startDate) ;
    if (numTokens < coinsRemaining) {
        coinsRemaining = safeSub(coinsRemaining, numTokens);

    } else {
        numTokens = coinsRemaining;
        coinsRemaining = 0;
    }
    require (token.transferFrom(ACT_Reserve,grantee,numTokens));
  }

  // Method for withdrawal in the case of failure
  function withdraw() {
      if (failed()) {
          if (deposits[msg.sender] > 0) {
              uint256 val = deposits[msg.sender];
              deposits[msg.sender] = 0;
              msg.sender.transfer(val);
          }
      }
  }

  // Method to manually clear funds and send it out to destination address
  function complete() onlyOwner {
      if (success()) {
          uint256 val = this.balance;
          if (val > 0) {
            if (!multiSig.send(val)) {
                log0("cannot withdraw");
            } else {
                log0("funds withdrawn");
            }
          } else {
              log0("nothing to withdraw");
          }
      }
  }

  // Method to stop crowdsale incase of emergencies. Funds will be forwarded to secure wallet address
  // Refunds will be issued from that address
  function emergencyStop() onlyOwner {
    endDate = now;
    pause();
    //Transfer funds from owner address to Secure wallet address
    if (!SecureWallet.send(this.balance)) {
        log0("cannot forward funds");
    }
  }
  }
