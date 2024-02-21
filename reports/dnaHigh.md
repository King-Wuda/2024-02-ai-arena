title: DNA sequence is not random and can be used to customize NFT and possibly get higher rank when using `reRoll` function

links:
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/AiArenaHelper.sol#L83-L121
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/FighterFarm.sol#L379-L390


## Impact
Anyone can reRoll fighter NFT and calculate what weight, element they will receivce and also the rarity of their NFT. This is supposed to be random so this will allow any user to get an unfair advantage and increase the rarity of their NFT.

## Vulnerability details
When someone want `reRoll` their fighter NFT to try their luck get a better NFT, the `dna` sequence is upposed to be a randomly generated sequence according to the docs. But because it uses this to calculate thier dna and then use the dna to calculate enerything else:

```solidity
        uint256 dna = uint256(keccak256(abi.encode(msg.sender, tokenId, numRerolls[tokenId])));
        (uint256 element, uint256 weight, uint256 newDna) = _createFighterBase(dna, fighterType);
        fighters[tokenId].element = element;
        fighters[tokenId].weight = weight;
        fighters[tokenId].physicalAttributes = _aiArenaHelperInstance.createPhysicalAttributes(
            newDna,
            generation[fighterType],
            fighters[tokenId].iconsType,
            fighters[tokenId].dendroidBool
        );
```
Anyone can calculate what weight, element and rarity they will receive with their dna sequence. Anyone can try out calculations with different addresses they own until they find the results they like and officially `reRoll` the NFT in the `fighterFarm.sol` contract.


## Proof of Concept
A person a has minted a fighter NFT from any of the relevant functions, `mintFromMergingPool(), redeemMintPass(), claimFighters()` and they do not like the NFT they have or believe they can get a better one.

They can use a simple contract to try out different addresses they own or have made, and use it to `reRoll` the NFT and see what the reesults will be for that address.

Here is a simple contract they can paste in remix or use foundry cast to see what the results will be for that address:

```solidity
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

    function reRoll(address user, uint256 tokenId, uint256 numReRollsNFT) public {

            dna = uint256(keccak256(abi.encode(user, tokenId, numRerollsNFT)));
            element = dna % 3;
            weight = dna % 31 + 65;
            // attributeToDnaDivisor[attributes[i]] = ...
            // uint256 rarityRank = (dna / attributeToDnaDivisor[attributes[i]]) % 100;
        }  
}
```

If they know attribute probalities they can take that into account and add it into the simple contract to estimate the rarityRank of their NFTs attributes.

## Tools Used
Manual review.

## Recommended Mitigation Steps
The protocol should add a mechanism to grab a random dna sequence as they said they would in their docs, whether they use chainlink VRF or they do it off-chain and put it onchain and pass it to the function they must just ensure that is it truly random and no-one can gain an unfair advantage from trying to estimate the results of the reRolls.