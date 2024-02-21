title: `setupAirdrop()` function lacks input validation check to ensure thta recipients array is too large for gas

links:
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/Neuron.sol#L127-L134

## Impact
`setupAirdrop()` function will run out of gas and fail.

## Proof of Concept
To prove this we will use foundry along with its gas reporting to run the `setupAirdrop()` function with alot of users and see how many it takes to reach the block gas limit.
Add this test to the `Neuron.t.sol` test file

```solidity
    function testSetupAirdropGasError() public { 
        // each user takes up 24726 gas without allowance check, 1214 uesrs to finish gas
        address[] memory recipients = new address[](11314);
        uint256[] memory amounts = new uint256[](11314);
        uint32 j = 3;
        for (uint32 i = 0; i < recipients.length; i++) {
        recipients[i] = vm.addr(j);
        amounts[i] = 1_000 * 10 ** 18;
        }
        _neuronContract.setupAirdrop(recipients, amounts);
       /* uint256 firstRecipient = _neuronContract.allowance(_treasuryAddress, recipients[0]);
        uint256 secondRecipient = _neuronContract.allowance(_treasuryAddress, recipients[1]);
        assertEq(firstRecipient, amounts[0]);
        assertEq(secondRecipient, amounts[0]); */
    }
```
It took approximately 11314 users to make `setupAirdrop` go above 30 million gas.

## Tools Used
Manual reveiw, foundry.

## Recommended Mitigation Steps
Protocol could either setup the airdrop in batches if it gets to large but they should also add a check to see that the receipients array is not too large and will therefore cosume unneccessary gas.

I will add a limit variable which will represent whatever limit of receipts they have chosen for that batch.

```diff
    function setupAirdrop(address[] calldata recipients, uint256[] calldata amounts) external {
        require(isAdmin[msg.sender]);
        require(recipients.length == amounts.length);
+       require(recipients.length, limit);
        uint256 recipientsLength = recipients.length;
        for (uint32 i = 0; i < recipientsLength; i++) {
            _approve(treasuryAddress, recipients[i], amounts[i]);
        }
    }
```