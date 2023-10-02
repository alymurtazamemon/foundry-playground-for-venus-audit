// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Handler {
    // * IXVSValut
    // * function requestWithdrawal(address _rewardToken, uint256 _pid, uint256 _amount) external;
    // * function deposit(address _rewardToken, uint256 _pid, uint256 _amount) external;
    // * ==================
    // * IPRIME
    // * function getPendingInterests(address user) external returns (PendingInterest[] memory pendingInterests);
    // * function updateScores(address[] memory users) external;
    // * function updateAlpha(uint128 _alphaNumerator, uint128 _alphaDenominator) external;
    // * function updateMultipliers(address market, uint256 supplyMultiplier, uint256 borrowMultiplier) external;
    // * function addMarket(address vToken, uint256 supplyMultiplier, uint256 borrowMultiplier) external;
    // * function setLimit(uint256 _irrevocableLimit, uint256 _revocableLimit) external;
    // * function issue(bool isIrrevocable, address[] calldata users) external;
    // * function xvsUpdated(address user) external
    // * function accrueInterestAndUpdateScore(address user, address market) external
    // * function claim() external;
    // * function burn(address user) external;
    // * function togglePause() external;
    // * function claimInterest(address vToken) external returns (uint256);
    // * function claimInterest(address vToken, address user) external returns (uint256);
    // * function updateAssetsState(address _comptroller, address asset) external;
    // * function accrueInterest(address vToken) public;
    // * function getInterestAccrued(address vToken, address user) public returns (uint256);
}
