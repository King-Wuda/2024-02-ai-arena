title:`transferFrom` will not revert on failed transaction

links:
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/Neuron.sol#L138-L145

## Impact
Caller may not receive tokens claimed

## Proof of Concept
When a caller calls `claim()` function in the `Neuron.sol` contract the function the calls `transferFrom` to transfer the claimed tokens to the `msg.sender`, however there no checks to ensure that the transfer was actually successful.

```solidity
 function claim(uint256 amount) external {
        require(
            allowance(treasuryAddress, msg.sender) >= amount, 
            "ERC20: claim amount exceeds allowance"
        );
        transferFrom(treasuryAddress, msg.sender, amount);
        emit TokensClaimed(msg.sender, amount);
    }
```

## Tools Used
manual review.

## Recommended Mitigation Steps
Add a `bool success` check to ensure that the transaction was successful or use `safetransferFrom` instead.

```diff
    function claim(uint256 amount) external {
        require(
            allowance(treasuryAddress, msg.sender) >= amount, 
            "ERC20: claim amount exceeds allowance"
        );
-       transferFrom(treasuryAddress, msg.sender, amount);
+       (bool succss) = transferFrom(treasuryAddress, msg.sender, amount);
+       require(success, "transfer failed");
        emit TokensClaimed(msg.sender, amount);
    }
```