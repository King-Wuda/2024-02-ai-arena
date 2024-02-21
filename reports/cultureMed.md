title: `claimRewards()` function lacks input validation check for `customAttributes`

links:
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/MergingPool.sol#L139-L160
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/FighterFarm.sol#L313-L331


## Impact
User could have no valid element for NFT and can make weight far above limit of 95 or below 65 if they so choose.

## Vulnerability details
The `customAttributes` are used to allow the person calling the function to pick the weight of their fighter NFT between 65 and 95 and also allow them to choose their element which is limited to the uint values of [0, 1, 2]. Despite these limits the protocol has no checks to ensure the person calling the function has entered valid , there are no checks whatsoever for this in both the `claimRewards()` function from the `MergingPool.sol` contract and the `mintFromMergingPool` function from the `FighterFarm.sol` contract.

## Proof of Concept
To that there are no checks we are going to call the claim rewards function with to mint 2 NFTs with weights of 800 and an element uint value of 5.

Use this test in the `MergingPool.t.sol` test file:

```solidity
    //////////////////////////// POC /////////////////////////
    /////////////////////////////////////////////////////////

    function testWrongCustomAttributes() public {
        _mintFromMergingPool(_ownerAddress);
        _mintFromMergingPool(_DELEGATED_ADDRESS);
        assertEq(_fighterFarmContract.ownerOf(0), _ownerAddress);
        assertEq(_fighterFarmContract.ownerOf(1), _DELEGATED_ADDRESS);
        uint256[] memory _winners = new uint256[](2);
        _winners[0] = 0;
        _winners[1] = 1;
        // winners of roundId 0 are picked
        _mergingPoolContract.pickWinner(_winners);
        assertEq(_mergingPoolContract.isSelectionComplete(0), true);
        assertEq(_mergingPoolContract.winnerAddresses(0, 0) == _ownerAddress, true);
        // winner matches ownerOf tokenId
        assertEq(_mergingPoolContract.winnerAddresses(0, 1) == _DELEGATED_ADDRESS, true);
        string[] memory _modelURIs = new string[](2);
        _modelURIs[0] = "ipfs://bafybeiaatcgqvzvz3wrjiqmz2ivcu2c5sqxgipv5w2hzy4pdlw7hfox42m";
        _modelURIs[1] = "ipfs://bafybeiaatcgqvzvz3wrjiqmz2ivcu2c5sqxgipv5w2hzy4pdlw7hfox42m";
        string[] memory _modelTypes = new string[](2);
        _modelTypes[0] = "original";
        _modelTypes[1] = "original";
        uint256[2][] memory _customAttributes = new uint256[2][](2);
        _customAttributes[0][0] = uint256(5);
        _customAttributes[0][1] = uint256(800);
        _customAttributes[1][0] = uint256(5);
        _customAttributes[1][1] = uint256(800);
        // winners of roundId 1 are picked
        _mergingPoolContract.pickWinner(_winners);
        // winner claims rewards for previous roundIds
        _mergingPoolContract.claimRewards(_modelURIs, _modelTypes, _customAttributes);
        // other winner claims rewards for previous roundIds
        vm.prank(_DELEGATED_ADDRESS);
        _mergingPoolContract.claimRewards(_modelURIs, _modelTypes, _customAttributes);
    }

## Tools Used
Manual Review and Foundry.

## Recommended Mitigation Steps
Add checks in `claimRewards` function by adding these lines along with own custom revert reason.

```diff
 function claimRewards(
        string[] calldata modelURIs, 
        string[] calldata modelTypes,
        uint256[2][] calldata customAttributes
    ) 
        external 
    {

        uint256 winnersLength;
        uint32 claimIndex = 0;
        uint32 lowerBound = numRoundsClaimed[msg.sender];
        for (uint32 currentRound = lowerBound; currentRound < roundId; currentRound++) {
            numRoundsClaimed[msg.sender] += 1;
            winnersLength = winnerAddresses[currentRound].length;
            for (uint32 j = 0; j < winnersLength; j++) {
                if (msg.sender == winnerAddresses[currentRound][j]) {
   +                 if (customAttributes[claimIndex][0] != 0 || customAttributes[claimIndex][0] != 1 || customAttributes[claimIndex][0] != 2) {
   +                     revert
   +                 }
   +                 if (customAttributes[claimIndex][1] < 65 || customAttributes[claimIndex][1] > 95) {
   +                     revert 
   +                 }
                    _fighterFarmInstance.mintFromMergingPool(
                        msg.sender,
                        modelURIs[claimIndex],
                        modelTypes[claimIndex],
                        customAttributes[claimIndex]
                    );
                    claimIndex += 1;
```