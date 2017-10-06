pragma solidity ^0.4.11;

library ArrayUtil {
  /** Finds the index of a given value in an array. */
  function IndexOf(address[] values, address value) returns(uint) {
    uint i = 0;
    while ((values[i] != value) && (i<values.length)) {
      i++;
    }
    return i;
  }

  /** Removes the given value in an array. */
  function RemoveByValue(address[] values, address value) {
    uint i = IndexOf(values,value);
    RemoveByIndex(values,i);
  }

  /** Removes the value at the given index in an array. */
  function RemoveByIndex(address[] values, uint i) {
    if(i<values.length){
      while (i<values.length-1) {
        values[i] = values[i+1];
        i++;
      }
      values.length-1;
    }
  }

}
