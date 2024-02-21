title: Any User can cause `_addResultPoints` function to revert on underflow if accumulatedPointsPerFighter != accumulatedPointsPerAddress in that current round

links:
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/RankedBattle.sol#L322-L349
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/RankedBattle.sol#L472-L490

## Impact
Attacker can prevent deduction of points to zero and therefore gain $NRN distributed at the end of the round. They will also avoid having their stake put at risk in any further losses until their points are reduced to zero.

## Vulnerability details
After a fight has taken place on the game server, the results are pushed onto the blockchain with the `updateBattleRecord()` function. After that if the user has staked their $NRN for that round the results are further pushed to the `_addResultPoints` function. The problem occurs here where the points are supposed to deducted if the fighter NFt has lost a fight, if the address of the nft owner has multiple NFTs fighting, its possible to cause the `accumulatedPointsPerAddress[fighterOwner][roundId] -= points` to underflow thereby resulting in the function reverting.

## Proof of Concept
To produce the scenario conducive to this attack we will make a player have 2 fighter NFTs with 10 $NRN and 5 $NRN staked on each one respectively for that round. We will also assume a gain/loss of 20 of their `eloFactor` upon every win/loss to make this more simple.

What will hapeen in this POC is that the first NFT will win their fight and gain points, then the second NFT will lose their fight with a less staking factor so therefore lose less points.
This will cause the `accumulatedPointsPerFighter[tokenId][roundId]` and `accumulatedPointsPerAddress[fighterOwner][roundId]` to have less points than `accumulatedPointsPerFighter`. When the first NFT loses now the `accumulatedPointsPerAddress[fighterOwner][roundId]` will underflow and revert when the `_addResultPoints` function is called.

This code can be used in the RankedBattle.t.sol test file and has been made to similarly reflect the test of the `testUpdateBattleRecordPlayerWonBattle`.

```solidity
    /////////////////////////////////////////////////
    /////////////////// POC /////////////////////////
    /////////////////////////////////////////////////

    function testUpdateBattleRecordExploit() public {
        address player = vm.addr(3);
        _mintFromMergingPool(player);
        _mintFromMergingPool(player);
        _fundUserWith4kNeuronByTreasury(player);
        vm.prank(player);
        _rankedBattleContract.stakeNRN(10 * 10 ** 18, 0);
        assertEq(_rankedBattleContract.amountStaked(0), 10 * 10 ** 18);
        vm.prank(player);
        _rankedBattleContract.stakeNRN(5 * 10 ** 18, 1);
        assertEq(_rankedBattleContract.amountStaked(1), 5 * 10 ** 18);
        vm.prank(address(_GAME_SERVER_ADDRESS));
        _rankedBattleContract.updateBattleRecord(0, 50, 0, 1520, true);
        vm.prank(address(_GAME_SERVER_ADDRESS));
        _rankedBattleContract.updateBattleRecord(1, 50, 2, 1500, true);
        vm.expectRevert();
        _rankedBattleContract.updateBattleRecord(0, 50, 2, 1480, true);
        assertEq(_rankedBattleContract.accumulatedPointsPerAddress(player, 0) > 0, true);
    }
```


## Tools Used
Manual review.

## Recommended Mitigation Steps
To mitigate this there should be another `points` variable to deduct the `accumulatedPointsPerAddress[fighterOwner][roundId]` to zero if `points > accumulatedPointsPerAddress[fighterOwner][roundId]`.

Make these changes to the `_addResultPoints()` function.

```diff
} else if (battleResult == 2) {
            /// If the user lost the match
+            uint256 pointsAddress;
            /// Do not allow users to lose more NRNs than they have in their staking pool
            if (curStakeAtRisk > amountStaked[tokenId]) {
                curStakeAtRisk = amountStaked[tokenId];
            }
            if (accumulatedPointsPerFighter[tokenId][roundId] > 0) {
                /// If the fighter has a positive point balance for this round, deduct points 
                points = stakingFactor[tokenId] * eloFactor;
                if (points > accumulatedPointsPerFighter[tokenId][roundId]) {
                    points = accumulatedPointsPerFighter[tokenId][roundId];
                }
+               if (points > accumulatedPointsPerAddress[fighterOwner][roundId]) {
+                   pointsAddress = accumulatedPointsPerAddress[fighterOwner][roundId];
+               }

                accumulatedPointsPerFighter[tokenId][roundId] -= points;
        
-               accumulatedPointsPerAddress[fighterOwner][roundId] -= points;
+               accumulatedPointsPerAddress[fighterOwner][roundId] -= pointsAddress;

                totalAccumulatedPoints[roundId] -= points;
```
