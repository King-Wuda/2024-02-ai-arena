// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract dna {
address public owner;
uint256 public dna;
uint256 public weight;
uint256 public element;

constructor() {
    owner = msg.sender;
}

 function reRoll(address user) public {


            // @audit-issue reroll to desired fighter predictable
            dna = uint256(keccak256(abi.encode(user, 50, 1)));
            element = dna % 3;
            weight = dna % 31 + 65;

            uint256 rarityRank = (dna / attributeToDnaDivisor[attributes[i]]) % 100;
    }  
}