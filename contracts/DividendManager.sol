pragma solidity ^0.4.11;

import "./OdinCoinToken.sol";
import "./browser/SafeMath.sol";


contract DividendManager is SafeMath{

    //using SafeMath for uint256;

    /*Handle for Token contract */
    OdinCoin public token;

    /* Handle payments we couldn't make. */
    mapping (address => uint256) public dividends;
    uint256 public totalPaidOut = 0;

    /* Indicates a payment is now available to a shareholder */
    event PaymentAvailable(address addr, uint256 amount);

    /* Indicates a dividend payment was made. */
    event DividendPayment(uint256 paymentPerShare, uint256 timestamp);

    /* Create our contract with references to token contract as required. */
    function DividendManager(address _tokenContractAddress) {

        token = OdinCoin(_tokenContractAddress);

    }

    function getDividends(address _addr) returns(uint256){
        return dividends[_addr];
    }

    /* Makes a dividend payment - we make it available to all senders then send the change back to the caller.  We don't actually send the payments to everyone to reduce gas cost and also to
       prevent potentially getting into a situation where we have recipients reverting causing dividend failures and having to consolidate their dividends in a separate process. */

       function () payable {
           uint256 validSupply;
           uint256 paymentPerShare;
           /* Determine how much to pay each shareholder. */
           validSupply = token.totalSupply();
           paymentPerShare = msg.value / validSupply;
           if (paymentPerShare == 0)
               revert();

           /* Enum all accounts and send them payment */
           //uint256 totalPaidOut = 0;
           for (uint256 i = 0; i < token.tokenHolderCount(); i++) {
               address addr = token.tokenHolder(i);
               uint256 dividend = paymentPerShare * token.balanceOf(addr);
               dividends[addr] = safeAdd(dividends[addr],dividend);
               PaymentAvailable(addr, dividend);
               totalPaidOut = safeAdd(totalPaidOut,dividend);
           }

           // Attempt to send change
           uint256 remainder = safeSub(msg.value,totalPaidOut);
           if (remainder > 0 && !msg.sender.send(remainder)) {
               dividends[msg.sender] = safeAdd(dividends[msg.sender],remainder);
               PaymentAvailable(msg.sender, remainder);
           }

           /* Audit this */
           DividendPayment(paymentPerShare, now);
       }


       /* Allows a user to request a withdrawal of their dividend in full. */
          function withdrawDividend() {
              // Ensure we have dividends available
              if (dividends[msg.sender] == 0)
                  revert();

              // Determine how much we're sending and reset the count
              uint256 dividend = dividends[msg.sender];
              dividends[msg.sender] = 0;

              // Attempt to withdraw
              if (!msg.sender.send(dividend))
                  revert();
          }



}
