pragma solidity ^0.4.11;

import "./browser/Pausable.sol";
import './browser/ERC20.sol';
import './browser/SafeMath.sol';
import './browser/StandardToken.sol';
//import './Arrayutil.sol';


contract OdinCoin is ERC20, SafeMath, Pausable, StandardToken {

  string public name;
  string public symbol;
  uint8  public const;

  /* List of all token holders */
   address[] public allTokenHolders;

   /* Our transfer event to fire whenever we shift SMRT around */
  event Transfer(address indexed from, address indexed to, uint256 value);

/* Our approval event when one user approves another to control */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);



  function OdinCoin(address reserve) {
    name = "Odin Token";
    symbol = "ODN";
    const = 8; // check if needed anymore

    totalSupply = 10**uint256(const);
    balances[reserve] = totalSupply;
  }


  /* Returns the total number of holders of this currency. */
 function tokenHolderCount() constant returns (uint256) {
     return allTokenHolders.length;
 }

 /* Gets the token holder at the specified index. */
 function tokenHolder(uint256 _index)  constant returns (address) {
     return allTokenHolders[_index];
 }

 function getallTokenHolders() constant returns (address[]){
     return allTokenHolders;
 }


 /* Transfer funds between two addresses that are not the current msg.sender - this requires approval to have been set separately and follows standard ERC20 guidelines */
 function transferFrom(address _from, address _to, uint256 _amount) returns (bool) {
     bool success=false;
     if (balances[_from] >= _amount && _amount > 0) {
         bool isNew = balances[_to] == 0;
         success=super.transferFrom(_from,_to,_amount);
         if (isNew){
             tokenOwnerAdd(_to);
           }
         if (balances[_from] == 0){
             tokenOwnerRemove(_from);
           }
         return success;
         }
     return success;

   }


   /* Transfer the balance from owner's account to another account */
       function transfer(address _to, uint256 _amount) returns (bool) {
           bool success=false;
           /* Check if sender has balance and for overflows */
           if (balances[msg.sender] < _amount || _amount < 0)
               return success;

           /* Do a check to see if they are new, if so we'll want to add it to our array */
           bool isRecipientNew = balances[_to] == 0;

           success=super.transfer(_to,_amount);

           /* Consolidate arrays if they are new or if sender now has empty balance */
           if (isRecipientNew)
               tokenOwnerAdd(_to);
           if (balances[msg.sender] < 1)
               tokenOwnerRemove(msg.sender);

             return success;
         }



     /* If the specified address is not in our owner list, add them - this can be called by descendents to ensure the database is kept up to date. */
     function tokenOwnerAdd(address _addr) internal {
             /* First check if they already exist */
         uint256 Count = allTokenHolders.length;
         for (uint256 i = 0; i < Count; i++)
         if (allTokenHolders[i] == _addr){
                     /* Already found so we can abort now */
             return;
           }
             /* They don't seem to exist, so let's add them */
          allTokenHolders.length++;
          allTokenHolders[allTokenHolders.length - 1] = _addr;
         }

      /* If the specified address is in our owner list, remove them - this can be called by descendents to ensure the database is kept up to date. */
      function tokenOwnerRemove(address _addr) internal {
         /* Find out where in our array they are */
         uint256 Count = allTokenHolders.length;
         uint256 foundIndex = 0;
         bool found = false;
         uint256 i;
         for (i = 0; i < Count; i++){
             if (allTokenHolders[i] == _addr) {
                 foundIndex = i;
                 found = true;
                 break;
               }
           }

         /* If we didn't find them just return */
         if (!found){
               return;
             }
         /* We now need to shuffle down the array */
         for (i = foundIndex; i < Count - 1; i++){
             allTokenHolders[i] = allTokenHolders[i + 1];
           }

         allTokenHolders.length--;

         }


}
